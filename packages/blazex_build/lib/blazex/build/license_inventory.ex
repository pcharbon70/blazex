defmodule BlazeX.Build.LicenseInventory do
  @moduledoc "Deterministic, path-free BH-06 shipped-input and build-lineage inventory."

  alias BlazeX.Build.LicensePolicy

  @label ~r/^[a-zA-Z0-9][a-zA-Z0-9._\/-]{0,255}$/

  def analyze!(inputs, %LicensePolicy{} = policy, repository_root)
      when is_list(inputs) and is_binary(repository_root) do
    components = Map.new(policy.components, &{&1["id"], &1})
    records = Map.new(policy.records, &{&1["id"], &1})
    notices = notices!(policy.records, repository_root)
    inputs = inputs!(inputs, policy.limits, components)
    shipped_components = component_rows(inputs, components)

    %{
      "schema_version" => "1.0.0",
      "policy_id" => policy.id,
      "policy_sha256" => policy.sha256,
      "inputs" => Enum.map(inputs, &input_record(&1, components)),
      "components" => shipped_components,
      "license_records" => license_rows(shipped_components, records),
      "build_lineage" =>
        policy.components
        |> Enum.filter(&(&1["scope"] == "build-only"))
        |> Enum.sort_by(& &1["id"]),
      "notices" => notices,
      "summary" => %{
        "inputs" => length(inputs),
        "input_bytes" => Enum.sum(Enum.map(inputs, &byte_size(&1["bytes"]))),
        "shipped_components" => length(shipped_components),
        "build_only_components" => Enum.count(policy.components, &(&1["scope"] == "build-only")),
        "license_records" => length(policy.records),
        "verified_notices" => length(notices)
      },
      "complete" => true
    }
  end

  def analyze!(_, _, _),
    do: raise(ArgumentError, "license inventory inputs, policy, or repository root are invalid")

  def assert_matches_secret_audit!(%{"inputs" => inventory}, %{"inputs" => audit})
      when is_list(inventory) and is_list(audit) do
    identity = fn row -> {row["label"], row["bytes"], row["sha256"]} end

    unless Enum.map(inventory, identity) == Enum.map(audit, identity),
      do: raise(ArgumentError, "license inventory does not match secret-audited inputs")

    :ok
  end

  def assert_matches_secret_audit!(_, _),
    do: raise(ArgumentError, "license inventory or secret audit report is malformed")

  defp inputs!(inputs, limits, components) do
    if length(inputs) > limits["max_inputs"],
      do: raise(ArgumentError, "license inventory input count exceeds explicit limit")

    rows =
      Enum.map(inputs, fn input ->
        unless is_map(input) and Map.keys(input) |> Enum.sort() == ~w(bytes component_id label) and
                 is_binary(input["label"]) and Regex.match?(@label, input["label"]) and
                 is_binary(input["bytes"]) and is_binary(input["component_id"]),
               do: raise(ArgumentError, "license inventory input is malformed")

        component = Map.get(components, input["component_id"])

        unless component && component["scope"] == "shipped",
          do: raise(ArgumentError, "license inventory input component is unknown or not shipped")

        if byte_size(input["bytes"]) > limits["max_input_bytes"],
          do: raise(ArgumentError, "license inventory input exceeds per-input byte limit")

        input
      end)
      |> Enum.sort_by(& &1["label"])

    if rows |> Enum.map(& &1["label"]) |> Enum.uniq() |> length() != length(rows),
      do: raise(ArgumentError, "duplicate license inventory input label")

    if Enum.sum(Enum.map(rows, &byte_size(&1["bytes"]))) > limits["max_total_bytes"],
      do: raise(ArgumentError, "license inventory inputs exceed aggregate byte limit")

    rows
  end

  defp notices!(records, root) do
    root = Path.expand(root)

    records
    |> Enum.reject(&is_nil(&1["notice_path"]))
    |> Enum.group_by(& &1["notice_path"])
    |> Enum.map(fn {relative, rows} ->
      path = Path.expand(relative, root)

      unless path == root or String.starts_with?(path, root <> "/"),
        do: raise(ArgumentError, "license notice path escapes repository root")

      unless File.regular?(path), do: raise(ArgumentError, "required license notice is missing")
      actual = digest(File.read!(path))
      expected = rows |> Enum.map(& &1["notice_sha256"]) |> Enum.uniq()

      unless expected == [actual],
        do: raise(ArgumentError, "required license notice digest mismatch")

      %{
        "path" => relative,
        "sha256" => actual,
        "license_record_ids" => rows |> Enum.map(& &1["id"]) |> Enum.sort()
      }
    end)
    |> Enum.sort_by(& &1["path"])
  end

  defp component_rows(inputs, components) do
    inputs
    |> Enum.group_by(& &1["component_id"])
    |> Enum.map(fn {id, rows} ->
      components[id]
      |> Map.put("input_count", length(rows))
      |> Map.put("input_bytes", Enum.sum(Enum.map(rows, &byte_size(&1["bytes"]))))
    end)
    |> Enum.sort_by(& &1["id"])
  end

  defp license_rows(component_rows, records) do
    component_rows
    |> Enum.flat_map(& &1["license_record_ids"])
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(&Map.fetch!(records, &1))
  end

  defp input_record(input, components) do
    component = Map.fetch!(components, input["component_id"])

    %{
      "label" => input["label"],
      "bytes" => byte_size(input["bytes"]),
      "sha256" => digest(input["bytes"]),
      "component_id" => input["component_id"],
      "license_record_ids" => component["license_record_ids"]
    }
  end

  defp digest(bytes),
    do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
