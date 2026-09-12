defmodule BlazeX.Build.SecretPolicy do
  @moduledoc "Validated fixed-signature policy for BH-06 secret exclusion."
  alias BlazeX.Build.JSON
  @enforce_keys [:id, :sha256, :key_fragments, :literal_rules, :limits]
  defstruct @enforce_keys
  @top ~w(key_fragments limits literal_rules policy_id schema_version)
  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @fragment ~r/^[a-z][a-z0-9_]{2,63}$/
  @limit_keys ~w(max_findings max_input_bytes max_inputs max_total_bytes)
  @ceilings %{
    "max_inputs" => 10_000,
    "max_input_bytes" => 134_217_728,
    "max_total_bytes" => 536_870_912,
    "max_findings" => 10_000
  }

  def new!(attributes) when is_map(attributes) do
    exact!(attributes, @top, "secret policy")

    unless attributes["schema_version"] == "1.0.0" and valid?(attributes["policy_id"], @id),
      do: raise(ArgumentError, "secret policy identity is invalid")

    fragments = fragments!(attributes["key_fragments"])
    rules = rules!(attributes["literal_rules"])
    limits = limits!(attributes["limits"])

    normalized = %{
      "schema_version" => "1.0.0",
      "policy_id" => attributes["policy_id"],
      "key_fragments" => Enum.sort(fragments),
      "literal_rules" => Enum.sort_by(rules, & &1["id"]),
      "limits" => limits
    }

    %__MODULE__{
      id: attributes["policy_id"],
      sha256: digest(normalized),
      key_fragments: fragments,
      literal_rules: rules,
      limits: limits
    }
  end

  def new!(_), do: raise(ArgumentError, "secret policy must be a map")

  defp fragments!(rows) when is_list(rows) do
    unless Enum.all?(rows, &valid?(&1, @fragment)),
      do: raise(ArgumentError, "secret key fragment is invalid")

    unique!(rows, & &1, "secret key fragment") |> Enum.sort()
  end

  defp fragments!(_), do: raise(ArgumentError, "secret key fragments must be a list")

  defp rules!(rows) when is_list(rows) do
    normalized =
      Enum.map(rows, fn row ->
        unless is_map(row), do: raise(ArgumentError, "secret literal rule is malformed")
        exact!(row, ~w(id literal reason), "secret literal rule")

        unless valid?(row["id"], @id) and is_binary(row["literal"]) and
                 byte_size(row["literal"]) in 4..128 and reason?(row["reason"]),
               do: raise(ArgumentError, "secret literal rule is invalid")

        row
      end)

    unique!(normalized, & &1["id"], "secret literal rule id")
    unique!(normalized, & &1["literal"], "secret literal signature")
    Enum.sort_by(normalized, & &1["id"])
  end

  defp rules!(_), do: raise(ArgumentError, "secret literal rules must be a list")

  defp limits!(limits) when is_map(limits) do
    exact!(limits, @limit_keys, "secret policy limits")

    unless Enum.all?(@ceilings, fn {key, ceiling} ->
             is_integer(limits[key]) and limits[key] in 1..ceiling
           end) and limits["max_input_bytes"] <= limits["max_total_bytes"],
           do: raise(ArgumentError, "secret policy limits are invalid")

    limits
  end

  defp limits!(_), do: raise(ArgumentError, "secret policy limits must be a map")

  defp unique!(rows, key, label) do
    if Enum.any?(Enum.group_by(rows, key), fn {_, matches} -> length(matches) > 1 end),
      do: raise(ArgumentError, "duplicate #{label}")

    rows
  end

  defp exact!(map, keys, label),
    do:
      unless(Map.keys(map) |> Enum.sort() == Enum.sort(keys),
        do: raise(ArgumentError, "#{label} has missing or unknown fields")
      )

  defp valid?(value, pattern), do: is_binary(value) and Regex.match?(pattern, value)

  defp reason?(value),
    do:
      is_binary(value) and byte_size(value) in 1..256 and
        not String.contains?(value, ["\n", "\r"])

  defp digest(value),
    do: :crypto.hash(:sha256, JSON.encode!(value) <> "\n") |> Base.encode16(case: :lower)
end
