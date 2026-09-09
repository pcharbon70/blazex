defmodule BlazeX.Component.Schema do
  @moduledoc "Closed, bounded candidate schema algebra. No custom code is executed."
  @reserved ~w(__struct__ host renderer dom socket pid process secret secrets password token resource html window document)
  @safe_integer 9_007_199_254_740_991

  def version, do: "0.2.0-bh05-schema-candidate"
  def error(code, path), do: {:error, %{code: code, path: path, contract: version()}}

  def name?(name) do
    is_binary(name) and byte_size(name) in 1..64 and String.valid?(name) and
      name not in @reserved and not String.starts_with?(name, "__")
  end

  def boundary?(%{kind: kind, root: root, owner: owner} = boundary) do
    map_size(boundary) == 3 and kind in [:local, :host, :persistence, :command, :renderer] and
      id?(root) and id?(owner) and (kind != :local or root == owner)
  end

  def boundary?(_boundary), do: false

  def valid?(schema), do: valid?(schema, 0)
  defp valid?(_schema, depth) when depth > 8, do: false

  defp valid?(type, _depth) when type in [:boolean, :integer, :float, :string, :opaque_id],
    do: true

  defp valid?({:integer, min, max}, _depth), do: integer?(min) and integer?(max) and min <= max
  defp valid?({:string, max}, _depth), do: is_integer(max) and max in 1..4096

  defp valid?({:enum, values}, _depth),
    do:
      list?(values, 64) and values != [] and Enum.all?(values, &scalar?/1) and
        length(Enum.uniq(values)) == length(values)

  defp valid?({:tuple, types}, depth),
    do: list?(types, 64) and Enum.all?(types, &valid?(&1, depth + 1))

  defp valid?({kind, type, max}, depth) when kind in [:list, :map],
    do: is_integer(max) and max in 0..256 and valid?(type, depth + 1)

  defp valid?({:record, fields}, depth) do
    list?(fields, 64) and
      Enum.all?(fields, fn
        {name, type} -> name?(name) and valid?(type, depth + 1)
        _ -> false
      end) and length(Enum.uniq_by(fields, &elem(&1, 0))) == length(fields)
  end

  defp valid?({:nullable, type}, depth), do: valid?(type, depth + 1)

  defp valid?({:custom, id, version, type}, depth),
    do: id?(id) and is_integer(version) and version in 1..65535 and valid?(type, depth + 1)

  defp valid?({:callable, arity}, _depth), do: is_integer(arity) and arity in 0..8
  defp valid?({:semantic, 1}, _depth), do: true
  defp valid?(_schema, _depth), do: false

  def host?(schema) do
    valid?(schema) and
      case schema do
        {:callable, _} -> false
        {:tuple, types} -> Enum.all?(types, &host?/1)
        {:record, fields} -> Enum.all?(fields, fn {_, type} -> host?(type) end)
        {kind, type, _} when kind in [:list, :map] -> host?(type)
        {:nullable, type} -> host?(type)
        {:custom, _, _, type} -> host?(type)
        _ -> true
      end
  end

  def normalize(schema, value, boundary, path \\ []) do
    cond do
      not valid?(schema) -> error(:invalid_schema, path)
      not boundary?(boundary) -> error(:invalid_boundary, [])
      boundary.kind != :local and not host?(schema) -> error(:local_only, path)
      true -> check(schema, value, boundary, path)
    end
  end

  defp check(:boolean, value, _b, p), do: accept(is_boolean(value), value, p)
  defp check(:integer, value, _b, p), do: accept(integer?(value), value, p)
  defp check(:float, value, _b, p), do: accept(is_float(value), value, p)
  defp check(:string, value, _b, p), do: accept(string?(value, 4096), value, p)
  defp check(:opaque_id, value, _b, p), do: accept(id?(value), value, p)

  defp check({:integer, min, max}, value, _b, p),
    do: accept(integer?(value) and value >= min and value <= max, value, p)

  defp check({:string, max}, value, _b, p), do: accept(string?(value, max), value, p)

  defp check({:enum, values}, value, _b, p),
    do: accept(scalar?(value) and Enum.any?(values, &(&1 === value)), value, p)

  defp check({:nullable, _type}, nil, _b, _p), do: {:ok, nil}
  defp check({:nullable, type}, value, b, p), do: check(type, value, b, p)
  defp check({:custom, _id, _version, type}, value, b, p), do: check(type, value, b, p)

  defp check({:tuple, types}, value, b, p) do
    values =
      if b.kind == :local and is_tuple(value) and tuple_size(value) <= 64,
        do: Tuple.to_list(value),
        else: value

    if list?(values, 64) and length(values) == length(types) do
      Enum.zip(types, values)
      |> sequence(b, p)
      |> case do
        {:ok, normalized} -> {:ok, List.to_tuple(normalized)}
        error -> error
      end
    else
      error(:type, p)
    end
  end

  defp check({:list, type, max}, value, b, p) do
    if list?(value, max), do: sequence(Enum.map(value, &{type, &1}), b, p), else: error(:type, p)
  end

  defp check({:map, type, max}, value, b, p) do
    if is_map(value) and not is_struct(value) and map_size(value) <= max and
         Enum.all?(Map.keys(value), &name?/1) do
      value
      |> Enum.sort()
      |> Enum.reduce_while({:ok, %{}}, fn {key, item}, {:ok, acc} ->
        # Dynamic map keys are not copied into diagnostics.
        case check(type, item, b, p ++ [:entry]) do
          {:ok, normalized} -> {:cont, {:ok, Map.put(acc, key, normalized)}}
          error -> {:halt, error}
        end
      end)
    else
      error(:type, p)
    end
  end

  defp check({:record, fields}, value, b, p) do
    names = Enum.map(fields, &elem(&1, 0))

    if is_map(value) and not is_struct(value) and Enum.sort(Map.keys(value)) == Enum.sort(names) do
      Enum.reduce_while(fields, {:ok, %{}}, fn {name, type}, {:ok, acc} ->
        case check(type, Map.fetch!(value, name), b, p ++ [name]) do
          {:ok, normalized} -> {:cont, {:ok, Map.put(acc, name, normalized)}}
          error -> {:halt, error}
        end
      end)
    else
      error(:record_shape, p)
    end
  end

  defp check({:semantic, 1}, value, b, p) do
    case value do
      %{"kind" => kind, "value" => item}
      when map_size(value) == 2 and kind in ["text", "number", "boolean"] ->
        type =
          case kind do
            "text" -> :string
            "number" -> :integer
            "boolean" -> :boolean
          end

        case check(type, item, b, p ++ [:value]) do
          {:ok, _} -> {:ok, value}
          error -> error
        end

      _ ->
        error(:semantic_value, p)
    end
  end

  defp check(
         {:callable, arity},
         %{owner: owner, callable: fun} = value,
         %{kind: :local, root: root},
         p
       )
       when map_size(value) == 2 do
    valid =
      owner == root and is_function(fun, arity) and
        :erlang.fun_info(fun, :type) == {:type, :external} and
        :erlang.fun_info(fun, :env) == {:env, []}

    accept(valid, value, p)
  end

  defp check({:callable, _}, _value, _b, p), do: error(:local_only, p)

  defp sequence(pairs, boundary, path) do
    pairs
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {{type, value}, index}, {:ok, acc} ->
      case check(type, value, boundary, path ++ [index]) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end
  end

  defp accept(true, value, _path), do: {:ok, value}
  defp accept(false, _value, path), do: error(:type, path)

  defp integer?(value),
    do: is_integer(value) and value >= -@safe_integer and value <= @safe_integer

  defp scalar?(value),
    do:
      is_nil(value) or is_boolean(value) or integer?(value) or is_float(value) or
        string?(value, 4096)

  defp string?(value, max),
    do: is_binary(value) and byte_size(value) <= max and String.valid?(value)

  defp id?(value), do: string?(value, 128) and byte_size(value) > 0
  def list?([], max), do: max >= 0
  def list?([_head | tail], max) when max > 0, do: list?(tail, max - 1)
  def list?(_value, _max), do: false
end
