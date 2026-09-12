defmodule BlazeX.Build.LicensePolicy do
  @moduledoc "Validated BH-06 component, license, notice, and provenance policy."

  alias BlazeX.Build.JSON

  @enforce_keys [:id, :sha256, :limits, :records, :components]
  defstruct @enforce_keys

  @top ~w(components license_records limits policy_id schema_version)
  @limit_keys ~w(max_input_bytes max_inputs max_total_bytes)
  @ceilings %{
    "max_inputs" => 10_000,
    "max_input_bytes" => 134_217_728,
    "max_total_bytes" => 536_870_912
  }
  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @record_id ~r/^[A-Z][A-Z0-9._\/-]{0,127}$/
  @digest ~r/^[0-9a-f]{64}$/

  def new!(attributes) when is_map(attributes) do
    exact!(attributes, @top, "license policy")

    unless attributes["schema_version"] == "1.0.0" and valid?(attributes["policy_id"], @id),
      do: raise(ArgumentError, "license policy identity is invalid")

    limits = limits!(attributes["limits"])
    records = records!(attributes["license_records"])
    components = components!(attributes["components"], records)

    normalized = %{
      "schema_version" => "1.0.0",
      "policy_id" => attributes["policy_id"],
      "limits" => limits,
      "license_records" => Enum.sort_by(records, & &1["id"]),
      "components" => Enum.sort_by(components, & &1["id"])
    }

    %__MODULE__{
      id: attributes["policy_id"],
      sha256: digest(normalized),
      limits: limits,
      records: records,
      components: components
    }
  end

  def new!(_), do: raise(ArgumentError, "license policy must be a map")

  defp records!(rows) when is_list(rows) and rows != [] do
    rows =
      Enum.map(rows, fn row ->
        unless is_map(row), do: raise(ArgumentError, "license record is malformed")
        exact!(row, ~w(disposition id license notice_path notice_sha256), "license record")

        unless valid?(row["id"], @record_id) and text?(row["license"], 256) and
                 row["disposition"] in ["known-retention-required", "private-development-only"],
               do: raise(ArgumentError, "license record is invalid")

        validate_notice!(row)
        row
      end)

    unique!(rows, & &1["id"], "license record id")
  end

  defp records!(_), do: raise(ArgumentError, "license records must be a non-empty list")

  defp components!(rows, records) when is_list(rows) and rows != [] do
    record_ids = MapSet.new(records, & &1["id"])

    rows =
      Enum.map(rows, fn row ->
        unless is_map(row), do: raise(ArgumentError, "license component is malformed")

        exact!(
          row,
          ~w(id license_record_ids name scope source version),
          "license component"
        )

        ids = row["license_record_ids"]

        unless valid?(row["id"], @id) and text?(row["name"], 128) and
                 text?(row["source"], 256) and text?(row["version"], 128) and
                 row["scope"] in ["shipped", "build-only"] and is_list(ids) and ids != [] and
                 Enum.all?(ids, &valid?(&1, @record_id)) and length(ids) == length(Enum.uniq(ids)) and
                 Enum.all?(ids, &MapSet.member?(record_ids, &1)),
               do: raise(ArgumentError, "license component is invalid")

        Map.put(row, "license_record_ids", Enum.sort(ids))
      end)

    unique!(rows, & &1["id"], "license component id")
  end

  defp components!(_, _), do: raise(ArgumentError, "license components must be a non-empty list")

  defp limits!(limits) when is_map(limits) do
    exact!(limits, @limit_keys, "license policy limits")

    unless Enum.all?(@ceilings, fn {key, ceiling} ->
             is_integer(limits[key]) and limits[key] in 1..ceiling
           end) and limits["max_input_bytes"] <= limits["max_total_bytes"],
           do: raise(ArgumentError, "license policy limits are invalid")

    limits
  end

  defp limits!(_), do: raise(ArgumentError, "license policy limits must be a map")

  defp validate_notice!(%{
         "disposition" => "private-development-only",
         "notice_path" => nil,
         "notice_sha256" => nil
       }),
       do: :ok

  defp validate_notice!(%{
         "disposition" => "known-retention-required",
         "notice_path" => path,
         "notice_sha256" => sha256
       }) do
    unless relative_path?(path) and valid?(sha256, @digest),
      do: raise(ArgumentError, "license record notice is invalid")
  end

  defp validate_notice!(_), do: raise(ArgumentError, "license record notice is invalid")

  defp relative_path?(path) when is_binary(path) and path != "",
    do:
      Path.type(path) == :relative and
        not Enum.any?(Path.split(path), &(&1 in ["", ".", ".."]))

  defp relative_path?(_), do: false

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

  defp text?(value, maximum),
    do:
      is_binary(value) and byte_size(value) in 1..maximum and
        not String.contains?(value, ["\n", "\r"])

  defp digest(value),
    do: :crypto.hash(:sha256, JSON.encode!(value) <> "\n") |> Base.encode16(case: :lower)
end
