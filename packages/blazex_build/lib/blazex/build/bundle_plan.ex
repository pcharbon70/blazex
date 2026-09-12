defmodule BlazeX.Build.BundlePlan do
  @moduledoc "Deterministic, path-free BH-06 base and feature-bundle plan."

  alias BlazeX.Build.{BundlePolicy, JSON}
  @label ~r/^bundle\/[A-Za-z][A-Za-z0-9_.]*\.beam$/

  def plan!(inputs, %BundlePolicy{} = policy) when is_list(inputs) do
    bundle_ids = MapSet.new([policy.base_id | Enum.map(policy.features, & &1["id"])])
    inputs = inputs!(inputs, policy, bundle_ids)
    enforce_feature_sets!(inputs, policy)
    enforce_startup!(inputs, policy)

    bundles =
      [
        %{"id" => policy.base_id, "kind" => "base", "entrypoint_ids" => []}
        | Enum.map(policy.features, &Map.put(&1, "kind", "feature"))
      ]
      |> Enum.map(&bundle_row(&1, inputs))
      |> Enum.sort_by(& &1["id"])

    records = Enum.map(inputs, &input_record/1)

    %{
      "schema_version" => "1.0.0",
      "policy_id" => policy.id,
      "policy_sha256" => policy.sha256,
      "bundles" => bundles,
      "inputs" => records,
      "summary" => %{
        "bundles" => length(bundles),
        "features" => length(policy.features),
        "inputs" => length(inputs),
        "input_bytes" => Enum.sum(Enum.map(inputs, &byte_size(&1["bytes"])))
      },
      "complete" => true
    }
  end

  def plan!(_, _), do: raise(ArgumentError, "bundle plan inputs or policy are invalid")

  defp inputs!(inputs, policy, bundle_ids) do
    if length(inputs) > policy.limits["max_inputs"],
      do: raise(ArgumentError, "bundle plan input count exceeds explicit limit")

    rows =
      Enum.map(inputs, fn input ->
        unless is_map(input) and
                 Map.keys(input) |> Enum.sort() == ~w(bundle_id bytes label module) and
                 is_binary(input["label"]) and Regex.match?(@label, input["label"]) and
                 is_binary(input["module"]) and is_binary(input["bytes"]) and
                 MapSet.member?(bundle_ids, input["bundle_id"]),
               do: raise(ArgumentError, "bundle plan input is malformed or has unknown ownership")

        unless input["label"] == "bundle/#{input["module"]}.beam",
          do: raise(ArgumentError, "bundle plan label and module disagree")

        if byte_size(input["bytes"]) > policy.limits["max_input_bytes"],
          do: raise(ArgumentError, "bundle plan input exceeds per-input byte limit")

        input
      end)
      |> Enum.sort_by(& &1["label"])

    unique!(rows, & &1["label"], "bundle input label")
    unique!(rows, & &1["module"], "bundle input module")

    if Enum.sum(Enum.map(rows, &byte_size(&1["bytes"]))) > policy.limits["max_total_bytes"],
      do: raise(ArgumentError, "bundle plan inputs exceed aggregate byte limit")

    rows
  end

  defp enforce_feature_sets!(inputs, policy) do
    Enum.each(policy.features, fn feature ->
      actual =
        inputs
        |> Enum.filter(&(&1["bundle_id"] == feature["id"]))
        |> Enum.map(& &1["module"])

      unless actual == feature["modules"],
        do:
          raise(
            ArgumentError,
            "feature bundle module set does not match policy: #{feature["id"]}"
          )
    end)
  end

  defp enforce_startup!(inputs, policy) do
    owners = Map.new(inputs, &{&1["module"], &1["bundle_id"]})

    unless Enum.all?(policy.startup_modules, &(owners[&1] == policy.base_id)),
      do: raise(ArgumentError, "startup modules must be present in the base bundle")
  end

  defp bundle_row(bundle, inputs) do
    rows = Enum.filter(inputs, &(&1["bundle_id"] == bundle["id"]))

    %{
      "id" => bundle["id"],
      "kind" => bundle["kind"],
      "entrypoint_ids" => bundle["entrypoint_ids"],
      "modules" => Enum.map(rows, & &1["module"]),
      "input_count" => length(rows),
      "input_bytes" => Enum.sum(Enum.map(rows, &byte_size(&1["bytes"]))),
      "input_set_sha256" => digest(Enum.map(rows, &input_record/1))
    }
  end

  defp input_record(input),
    do: %{
      "label" => input["label"],
      "module" => input["module"],
      "bundle_id" => input["bundle_id"],
      "bytes" => byte_size(input["bytes"]),
      "sha256" => digest_bytes(input["bytes"])
    }

  defp unique!(rows, key, label) do
    if Enum.any?(Enum.group_by(rows, key), fn {_, matches} -> length(matches) > 1 end),
      do: raise(ArgumentError, "duplicate #{label}")
  end

  defp digest(value), do: digest_bytes(JSON.encode!(value) <> "\n")
  defp digest_bytes(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
