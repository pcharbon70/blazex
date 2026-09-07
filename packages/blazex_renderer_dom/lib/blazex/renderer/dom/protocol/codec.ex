defmodule BlazeX.Renderer.DOM.Protocol.Codec do
  @moduledoc "Bounded canonical bytes for the internal Phase 2 protocol."
  @maximum 131_072

  def encode(value) do
    try do
      {:ok, encode!(value)}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def encode!(value) do
    bytes = value |> write(0) |> IO.iodata_to_binary()
    require!(byte_size(bytes) <= @maximum, "limit")
    bytes
  end

  def decode(bytes) when is_binary(bytes) do
    try do
      require!(byte_size(bytes) <= @maximum, "limit")
      {value, rest} = parse(bytes, 0)
      require!(rest == "" and encode!(value) == bytes)
      {:ok, value}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def decode(_), do: {:error, "malformed"}
  def digest(value), do: :crypto.hash(:sha256, encode!(value)) |> Base.encode16(case: :lower)
  def require!(true, _code), do: :ok
  def require!(_, code), do: throw({:protocol, code})
  def require!(value), do: require!(value, "malformed")

  defp write(_, depth) when depth > 32, do: throw({:protocol, "limit"})
  defp write(nil, _), do: "n"
  defp write(true, _), do: "t"
  defp write(false, _), do: "f"

  defp write(value, _) when is_integer(value) and value >= 0 and value <= 9_007_199_254_740_991,
    do: ["i", Integer.to_string(value), ";"]

  defp write(value, _) when is_binary(value) do
    require!(String.valid?(value))
    require!(byte_size(value) <= 4096, "limit")
    ["s", Integer.to_string(byte_size(value)), ":", value]
  end

  defp write(value, depth) when is_list(value) do
    require!(length(value) <= 1024, "limit")
    ["a", Integer.to_string(length(value)), ":", bounded_map(value, &write(&1, depth + 1))]
  end

  defp write(%{__struct__: _}, _), do: throw({:protocol, "malformed"})

  defp write(value, depth) when is_map(value) do
    require!(map_size(value) <= 64)
    keys = Enum.sort(Map.keys(value))
    require!(Enum.all?(keys, &(is_binary(&1) and Regex.match?(~r/^[a-z][a-z0-9_]{0,63}$/, &1))))

    [
      "m",
      Integer.to_string(map_size(value)),
      ":",
      bounded_map(keys, fn key ->
        [write(key, depth + 1), write(Map.fetch!(value, key), depth + 1)]
      end)
    ]
  end

  defp write(_, _), do: throw({:protocol, "malformed"})

  defp bounded_map(values, mapper) do
    {result, _} =
      Enum.map_reduce(values, 0, fn value, used ->
        output = mapper.(value)
        total = used + :erlang.iolist_size(output)
        require!(total <= @maximum, "limit")
        {output, total}
      end)

    result
  end

  defp count(bytes, separator) do
    case :binary.split(bytes, separator) do
      [token, rest] ->
        require!(
          String.valid?(token) and byte_size(token) <= 16 and
            Regex.match?(~r/^(0|[1-9][0-9]*)$/, token)
        )

        value = String.to_integer(token)
        require!(value <= 9_007_199_254_740_991)
        {value, rest}

      _ ->
        throw({:protocol, "malformed"})
    end
  end

  defp parse(_, depth) when depth > 32, do: throw({:protocol, "limit"})
  defp parse("n" <> rest, _), do: {nil, rest}
  defp parse("t" <> rest, _), do: {true, rest}
  defp parse("f" <> rest, _), do: {false, rest}
  defp parse("i" <> rest, _), do: count(rest, ";")

  defp parse("s" <> rest, _) do
    {size, rest} = count(rest, ":")
    require!(size <= 4096, "limit")
    require!(byte_size(rest) >= size)
    <<value::binary-size(size), tail::binary>> = rest
    require!(String.valid?(value))
    {value, tail}
  end

  defp parse("a" <> rest, depth) do
    {size, rest} = count(rest, ":")
    require!(size <= 1024, "limit")
    collection(size, rest, depth, [])
  end

  defp parse("m" <> rest, depth) do
    {size, rest} = count(rest, ":")
    require!(size <= 64, "limit")
    mapping(size, rest, depth, %{})
  end

  defp parse(_, _), do: throw({:protocol, "malformed"})
  defp collection(0, rest, _, result), do: {Enum.reverse(result), rest}

  defp collection(n, rest, depth, result) do
    {value, rest} = parse(rest, depth + 1)
    collection(n - 1, rest, depth, [value | result])
  end

  defp mapping(0, rest, _, result), do: {result, rest}

  defp mapping(n, rest, depth, result) do
    {key, rest} = parse(rest, depth + 1)
    require!(is_binary(key) and Regex.match?(~r/^[a-z][a-z0-9_]{0,63}$/, key))
    require!(not Map.has_key?(result, key))
    {value, rest} = parse(rest, depth + 1)
    mapping(n - 1, rest, depth, Map.put(result, key, value))
  end
end
