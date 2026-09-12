defmodule BlazeX.Build.JSON do
  @moduledoc false

  def encode!(value), do: encode(value)

  defp encode(value) when is_map(value) do
    value
    |> Enum.map(fn {key, item} -> {to_string(key), item} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map_join(",", fn {key, item} -> encode(key) <> ":" <> encode(item) end)
    |> then(&("{" <> &1 <> "}"))
  end

  defp encode(value) when is_list(value), do: "[" <> Enum.map_join(value, ",", &encode/1) <> "]"
  defp encode(value) when is_binary(value), do: "\"" <> escape(value) <> "\""
  defp encode(value) when is_integer(value) or is_float(value), do: to_string(value)
  defp encode(true), do: "true"
  defp encode(false), do: "false"
  defp encode(nil), do: "null"
  defp encode(value), do: raise(ArgumentError, "unsupported JSON value: #{inspect(value)}")

  defp escape(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end
end
