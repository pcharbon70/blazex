defmodule BlazeX.Component.Props do
  @moduledoc "Ordered declarations and atomic prop normalization; no component callbacks."
  alias BlazeX.Component.Schema
  @options [:type, :required, :default, :boundary, :doc, :deprecated, :version]

  def declare(declarations) do
    if Schema.list?(declarations, 64) do
      Enum.reduce_while(declarations, {:ok, []}, fn declaration, {:ok, acc} ->
        case field(declaration) do
          {:ok, field} ->
            if Enum.any?(acc, &(&1.name == field.name)),
              do: {:halt, Schema.error(:duplicate_prop, [])},
              else: {:cont, {:ok, acc ++ [field]}}

          error ->
            {:halt, error}
        end
      end)
    else
      Schema.error(:invalid_props_schema, [])
    end
  end

  defp field({name, options}) do
    with true <- Schema.name?(name),
         true <- Keyword.keyword?(options),
         true <- length(Keyword.keys(options)) == length(Enum.uniq(Keyword.keys(options))),
         true <- Enum.all?(Keyword.keys(options), &(&1 in @options)),
         type <- Keyword.get(options, :type),
         true <- Schema.valid?(type),
         required <- Keyword.get(options, :required, false),
         true <- is_boolean(required),
         false <- required and Keyword.has_key?(options, :default),
         boundary <- Keyword.get(options, :boundary, :host),
         true <- boundary in [:host, :local],
         true <- boundary == :local or Schema.host?(type),
         doc <- Keyword.get(options, :doc, ""),
         deprecated <- Keyword.get(options, :deprecated, nil),
         true <- text?(doc) and (is_nil(deprecated) or text?(deprecated)),
         version <- Keyword.get(options, :version, 1),
         true <- is_integer(version) and version in 1..65535 do
      default =
        if Keyword.has_key?(options, :default),
          do: {:present, Keyword.fetch!(options, :default)},
          else: :absent

      field = %{
        name: name,
        type: type,
        required: required,
        default: default,
        boundary: boundary,
        doc: doc,
        deprecated: deprecated,
        version: version
      }

      case default do
        :absent ->
          {:ok, field}

        {:present, value} ->
          # Defaults must be host-safe even for local declarations; executable defaults are forbidden.
          case Schema.normalize(type, value, %{kind: :host, root: "default", owner: "default"}, [
                 name
               ]) do
            {:ok, normalized} -> {:ok, %{field | default: {:present, normalized}}}
            _ -> Schema.error(:invalid_default, [name])
          end
      end
    else
      _ -> Schema.error(:invalid_prop_declaration, [])
    end
  end

  defp field(_field), do: Schema.error(:invalid_prop_declaration, [])
  defp text?(value), do: is_binary(value) and byte_size(value) <= 4096 and String.valid?(value)

  def normalize(declarations, values, boundary) do
    with {:ok, fields} <- declare(declarations), true <- Schema.boundary?(boundary) do
      normalize_fields(fields, values, boundary, [])
    else
      false -> Schema.error(:invalid_boundary, [])
      error -> error
    end
  end

  def normalize_fields(fields, values, boundary, path) do
    names = Enum.map(fields, & &1.name)

    cond do
      not is_map(values) or is_struct(values) ->
        Schema.error(:props_shape, path)

      Enum.any?(Map.keys(values), &(&1 not in names)) ->
        Schema.error(:unknown_prop, path)

      true ->
        Enum.reduce_while(fields, {:ok, %{}}, fn field, {:ok, acc} ->
          value =
            case Map.fetch(values, field.name) do
              {:ok, item} -> {:present, item}
              :error -> field.default
            end

          result =
            cond do
              value == :absent and field.required ->
                Schema.error(:required, path ++ [field.name])

              value == :absent ->
                {:ok, :absent}

              field.boundary == :local and boundary.kind != :local ->
                Schema.error(:local_only, path ++ [field.name])

              true ->
                {:present, item} = value
                # Defaults were normalized already; tuples are a canonical local representation.
                checked = if not Map.has_key?(values, field.name), do: wire(item), else: item

                case Schema.normalize(field.type, checked, boundary, path ++ [field.name]) do
                  {:ok, normalized} -> {:ok, {:present, normalized}}
                  error -> error
                end
            end

          case result do
            {:ok, :absent} -> {:cont, {:ok, acc}}
            {:ok, {:present, item}} -> {:cont, {:ok, Map.put(acc, field.name, item)}}
            error -> {:halt, error}
          end
        end)
    end
  end

  @doc "Returns JSON-compatible wire terms, not serialized JSON bytes. Local values fail closed."
  def encode(declarations, values, boundary) do
    if Schema.boundary?(boundary) and boundary.kind != :local do
      with {:ok, normalized} <- normalize(declarations, wire(values), boundary),
           do: {:ok, wire(normalized)}
    else
      Schema.error(:invalid_boundary, [])
    end
  end

  defp wire(value), do: wire(value, 0)
  defp wire(_value, depth) when depth > 16, do: :invalid_wire

  defp wire(value, depth) when is_tuple(value) and tuple_size(value) <= 256,
    do: value |> Tuple.to_list() |> Enum.map(&wire(&1, depth + 1))

  defp wire(value, depth) when is_list(value) do
    if Schema.list?(value, 256), do: Enum.map(value, &wire(&1, depth + 1)), else: :invalid_wire
  end

  defp wire(value, depth) when is_map(value) and not is_struct(value) and map_size(value) <= 256,
    do: Map.new(value, fn {k, v} -> {k, wire(v, depth + 1)} end)

  defp wire(value, _depth), do: value
end
