defmodule BlazeX.Renderer.DOM.ProtocolV2.IntentData do
  @moduledoc "Closed, reversible intent cells. Decoding never creates atoms or host objects."
  alias BlazeX.Renderer.DOM.Protocol.Codec

  @events %{
    "activate" => "click",
    "change" => "input",
    "submit" => "submit",
    "select" => "change",
    "expand" => "click",
    "dismiss" => "click",
    "move" => "pointermove",
    "reorder" => "drop",
    "increment" => "click",
    "decrement" => "click",
    "request_open" => "click",
    "request_close" => "click",
    "request_page" => "click"
  }

  def pack(nil), do: nil
  def pack(value), do: value |> normalize() |> Codec.encode!() |> Base.encode64()
  def unpack(nil), do: nil

  def unpack(value) do
    {:ok, bytes} = Base.decode64(value)
    {:ok, data} = Codec.decode(bytes)
    restore(data)
  end

  def count(nil), do: 0
  def count(value), do: length(unpack(value))
  def valid?(name, nil), do: name in ~w(focus selection listeners)

  def valid?(name, value) when is_binary(value) and byte_size(value) <= 4096 do
    with {:ok, bytes} <- Base.decode64(value),
         true <- Base.encode64(bytes) == value,
         {:ok, data} <- Codec.decode(bytes) do
      valid_data?(name, data)
    else
      _ -> false
    end
  end

  def valid?(_, _), do: false

  defp normalize(%{"type" => "integer", "value" => value}) when is_integer(value),
    do: %{"type" => "integer", "value" => Integer.to_string(value)}

  defp normalize(value) when is_map(value), do: Map.new(value, fn {k, v} -> {k, normalize(v)} end)
  defp normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)
  defp normalize(value), do: value

  defp restore(%{"type" => "integer", "value" => value}),
    do: %{"type" => "integer", "value" => String.to_integer(value)}

  defp restore(value) when is_map(value), do: Map.new(value, fn {k, v} -> {k, restore(v)} end)
  defp restore(value) when is_list(value), do: Enum.map(value, &restore/1)
  defp restore(value), do: value
  defp keys?(value, keys), do: is_map(value) and Enum.sort(Map.keys(value)) == Enum.sort(keys)
  defp bounded?(n, max), do: is_integer(n) and n >= 0 and n <= max
  defp portable?(value, depth \\ 0)

  defp portable?(value, depth) when depth <= 8 do
    keys?(value, ~w(type value)) and
      case value["type"] do
        "atom" ->
          is_binary(value["value"]) and byte_size(value["value"]) in 1..256 and
            value["value"] != "nil"

        "binary" ->
          is_binary(value["value"]) and byte_size(value["value"]) in 1..256

        "integer" ->
          is_binary(value["value"]) and
            Regex.run(~r/^(?:0|-?[1-9][0-9]*)$/, value["value"]) == [value["value"]]

        type when type in ["list", "tuple"] ->
          is_list(value["value"]) and length(value["value"]) in 1..32 and
            Enum.all?(value["value"], &portable?(&1, depth + 1))

        _ ->
          false
      end
  end

  defp portable?(_, _), do: false

  defp identity?(v),
    do:
      keys?(v, ~w(root path generation)) and portable?(v["root"]) and is_list(v["path"]) and
        length(v["path"]) <= 32 and Enum.all?(v["path"], &portable?/1) and
        bounded?(v["generation"], 9_007_199_254_740_991) and v["generation"] > 0

  defp valid_data?("focus", v) do
    keys?(v, ~w(behavior order auto_focus restore wrap)) and is_boolean(v["auto_focus"]) and
      is_boolean(v["wrap"]) and v["restore"] in ~w(none previous) and
      case v["behavior"] do
        "none" ->
          v["order"] == nil and not v["auto_focus"] and v["restore"] == "none" and not v["wrap"]

        "target" ->
          bounded?(v["order"], 1_000_000) and v["restore"] == "none" and not v["wrap"]

        "scope" ->
          v["order"] == nil and not v["auto_focus"]

        _ ->
          false
      end
  end

  defp valid_data?("selection", v) do
    keys?(v, ~w(kind value)) and
      case v["kind"] do
        "none" ->
          v["value"] == nil

        "single" ->
          portable?(v["value"])

        "multiple" ->
          is_list(v["value"]) and length(v["value"]) <= 256 and
            Enum.uniq(v["value"]) == v["value"] and Enum.all?(v["value"], &portable?/1)

        "text_range" ->
          keys?(v["value"], ~w(anchor focus direction)) and
            bounded?(v["value"]["anchor"], 1_000_000_000) and
            bounded?(v["value"]["focus"], 1_000_000_000) and
            v["value"]["direction"] in ~w(forward backward)

        _ ->
          false
      end
  end

  defp valid_data?("listeners", values) when is_list(values) do
    length(values) <= 256 and
      Enum.all?(values, fn v ->
        keys?(v, ~w(semantic native owner source)) and Map.has_key?(@events, v["semantic"]) and
          @events[v["semantic"]] == v["native"] and identity?(v["owner"]) and
          identity?(v["source"]) and v["owner"]["root"] == v["source"]["root"] and
          v["owner"]["generation"] == v["source"]["generation"] and
          List.starts_with?(v["source"]["path"], v["owner"]["path"])
      end) and Enum.map(values, & &1["semantic"]) |> then(&(Enum.sort(Enum.uniq(&1)) == &1))
  end

  defp valid_data?(_, _), do: false
end
