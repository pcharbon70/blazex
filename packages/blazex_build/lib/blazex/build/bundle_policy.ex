defmodule BlazeX.Build.BundlePolicy do
  @moduledoc "Validated BH-06 base and feature-bundle ownership policy."

  alias BlazeX.Build.JSON

  @enforce_keys [:id, :sha256, :base_id, :startup_modules, :features, :limits]
  defstruct @enforce_keys

  @top ~w(base_bundle_id features limits policy_id schema_version startup_modules)
  @limits ~w(max_bundles max_input_bytes max_inputs max_total_bytes)
  @ceilings %{
    "max_bundles" => 256,
    "max_inputs" => 10_000,
    "max_input_bytes" => 134_217_728,
    "max_total_bytes" => 536_870_912
  }
  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/

  def new!(attributes) when is_map(attributes) do
    exact!(attributes, @top, "bundle policy")

    unless attributes["schema_version"] == "1.0.0" and valid_id?(attributes["policy_id"]) and
             valid_id?(attributes["base_bundle_id"]),
           do: raise(ArgumentError, "bundle policy identity is invalid")

    startup = modules!(attributes["startup_modules"], "startup modules")
    features = features!(attributes["features"], attributes["base_bundle_id"])
    feature_modules = Enum.flat_map(features, & &1["modules"])

    if Enum.any?(startup, &(&1 in feature_modules)),
      do: raise(ArgumentError, "startup module cannot belong to a feature bundle")

    limits = limits!(attributes["limits"])

    if length(features) + 1 > limits["max_bundles"],
      do: raise(ArgumentError, "bundle policy exceeds bundle count limit")

    normalized = %{
      "schema_version" => "1.0.0",
      "policy_id" => attributes["policy_id"],
      "base_bundle_id" => attributes["base_bundle_id"],
      "startup_modules" => Enum.sort(startup),
      "features" => Enum.sort_by(features, & &1["id"]),
      "limits" => limits
    }

    %__MODULE__{
      id: attributes["policy_id"],
      sha256: digest(normalized),
      base_id: attributes["base_bundle_id"],
      startup_modules: startup,
      features: features,
      limits: limits
    }
  end

  def new!(_), do: raise(ArgumentError, "bundle policy must be a map")

  defp features!(rows, base_id) when is_list(rows) and rows != [] do
    rows =
      Enum.map(rows, fn row ->
        unless is_map(row), do: raise(ArgumentError, "feature bundle is malformed")
        exact!(row, ~w(entrypoint_ids id modules), "feature bundle")
        entries = ids!(row["entrypoint_ids"], "feature entrypoint ids")
        modules = modules!(row["modules"], "feature modules")

        unless valid_id?(row["id"]) and row["id"] != base_id,
          do: raise(ArgumentError, "feature bundle identity is invalid")

        %{"id" => row["id"], "entrypoint_ids" => entries, "modules" => modules}
      end)

    unique!(rows, & &1["id"], "feature bundle id")
    unique!(Enum.flat_map(rows, & &1["modules"]), & &1, "feature module")
    unique!(Enum.flat_map(rows, & &1["entrypoint_ids"]), & &1, "feature entrypoint")
    Enum.sort_by(rows, & &1["id"])
  end

  defp features!(_, _), do: raise(ArgumentError, "features must be a non-empty list")

  defp modules!(values, label) when is_list(values) and values != [] do
    unless Enum.all?(values, &module?/1), do: raise(ArgumentError, "#{label} are invalid")
    unique!(values, & &1, label) |> Enum.sort()
  end

  defp modules!(_, label), do: raise(ArgumentError, "#{label} must be a non-empty list")

  defp ids!(values, label) when is_list(values) and values != [] do
    unless Enum.all?(values, &valid_id?/1), do: raise(ArgumentError, "#{label} are invalid")
    unique!(values, & &1, label) |> Enum.sort()
  end

  defp ids!(_, label), do: raise(ArgumentError, "#{label} must be a non-empty list")

  defp limits!(limits) when is_map(limits) do
    exact!(limits, @limits, "bundle policy limits")

    unless Enum.all?(@ceilings, fn {key, ceiling} ->
             is_integer(limits[key]) and limits[key] in 1..ceiling
           end) and limits["max_bundles"] >= 2 and
             limits["max_input_bytes"] <= limits["max_total_bytes"],
           do: raise(ArgumentError, "bundle policy limits are invalid")

    limits
  end

  defp limits!(_), do: raise(ArgumentError, "bundle policy limits must be a map")

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

  defp valid_id?(value), do: is_binary(value) and Regex.match?(@id, value)

  defp module?(value),
    do:
      is_binary(value) and byte_size(value) in 1..256 and
        Regex.match?(~r/^[A-Za-z][A-Za-z0-9_.]*$/, value)

  defp digest(value),
    do: :crypto.hash(:sha256, JSON.encode!(value) <> "\n") |> Base.encode16(case: :lower)
end
