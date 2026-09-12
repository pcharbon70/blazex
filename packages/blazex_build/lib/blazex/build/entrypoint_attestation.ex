defmodule BlazeX.Build.EntryPointAttestation do
  @moduledoc "Builds and verifies deterministic per-entrypoint BH-06 accounting."

  alias BlazeX.Build.{EntryPointAccountingPolicy, JSON}

  @private_roles %{
    "reachability" => "reachability-report",
    "client_safety" => "client-safety-report",
    "compatibility" => "compatibility-report",
    "secret_audit" => "secret-audit-report",
    "license_inventory" => "license-inventory-report",
    "bundle_plan" => "bundle-plan-report",
    "runtime_closure" => "runtime-closure-report"
  }

  def build!(manifest, reports, %EntryPointAccountingPolicy{} = policy)
      when is_map(manifest) and is_map(reports) do
    entrypoint = Map.fetch!(manifest, "entrypoint")

    unless entrypoint in policy.entrypoints,
      do: invalid!(entrypoint["id"], "entrypoint is undeclared")

    unless Enum.sort(Map.keys(reports)) == policy.evidence,
      do: invalid!(entrypoint["id"], "evidence categories are missing or unknown")

    artifacts = artifacts!(manifest, policy, entrypoint["id"])
    evidence = evidence!(manifest, reports, artifacts, entrypoint["id"])
    payload = reports["payload"]
    licenses = reports["license_inventory"]

    %{
      "schema_version" => "1.0.0",
      "attestation_id" => "#{policy.id}/#{entrypoint["id"]}",
      "policy_id" => policy.id,
      "policy_sha256" => canonical_sha256(policy.canonical),
      "entrypoint" => entrypoint,
      "manifest" => %{
        "id" => Map.fetch!(manifest, "manifest_id"),
        "sha256" => canonical_sha256(manifest),
        "support_state" => Map.fetch!(manifest, "support_state")
      },
      "artifacts" => artifacts,
      "evidence" => evidence,
      "summary" => %{
        "artifacts" => length(artifacts),
        "public_artifacts" => Enum.count(artifacts, &(&1["exposure"] == "public")),
        "private_artifacts" =>
          Enum.count(artifacts, &(&1["exposure"] == "private-build-evidence")),
        "shipped_components" => licenses["summary"]["shipped_components"],
        "license_records" => licenses["summary"]["license_records"],
        "public_decoded_bytes" => payload["summary"]["public_decoded_bytes"],
        "public_brotli_bytes" => payload["summary"]["public_brotli_bytes"],
        "failed_budgets" => payload["summary"]["failed_budgets"]
      },
      "decision" => "accept"
    }
  end

  def build!(_, _, _), do: invalid!("unknown", "inputs are malformed")

  def verify!(attestation, manifest, reports, %EntryPointAccountingPolicy{} = policy) do
    unless attestation == build!(manifest, reports, policy),
      do: invalid!(get_in(attestation, ["entrypoint", "id"]) || "unknown", "attestation drift")

    :ok
  end

  def assert_complete_set!(attestations, %EntryPointAccountingPolicy{} = policy)
      when is_list(attestations) do
    observed = Enum.map(attestations, &get_in(&1, ["entrypoint", "id"]))
    expected = Enum.map(policy.entrypoints, & &1["id"])

    unless observed == expected,
      do: invalid!("set", "attestation set does not match declared entrypoints")

    :ok
  end

  def assert_complete_set!(_, _), do: invalid!("set", "attestation set is malformed")

  defp artifacts!(manifest, policy, id) do
    rows = Map.fetch!(manifest, "artifacts")

    unless is_list(rows) and rows != [] and length(rows) <= policy.limits["max_artifacts"],
      do: invalid!(id, "artifact count is outside limits")

    roles = MapSet.new(Enum.map(rows, & &1["role"]))
    expected = MapSet.new(policy.public_roles ++ policy.private_roles)
    unless roles == expected, do: invalid!(id, "artifact role coverage is incomplete or unknown")

    Enum.each(rows, fn row ->
      expected_exposure =
        if row["role"] in policy.public_roles, do: "public", else: "private-build-evidence"

      unless row["exposure"] == expected_exposure and is_binary(row["sha256"]) and
               is_binary(row["integrity"]) and is_integer(row["bytes"]) and row["bytes"] >= 0,
             do: invalid!(id, "artifact identity or exposure is malformed")
    end)

    rows
    |> Enum.map(
      &Map.take(&1, ~w(path role exposure sha256 integrity bytes cache_control feature_id))
    )
    |> Enum.sort_by(& &1["path"])
  end

  defp evidence!(manifest, reports, artifacts, id) do
    Enum.into(reports, %{}, fn {category, report} ->
      unless is_map(report) and accepted?(category, report, manifest),
        do: invalid!(id, "#{category} decision is not accepted")

      case @private_roles[category] do
        nil ->
          :ok

        role ->
          artifact =
            Enum.find(artifacts, &(&1["role"] == role)) ||
              invalid!(id, "#{category} artifact is missing")

          unless artifact["sha256"] == canonical_sha256(report),
            do: invalid!(id, "#{category} artifact identity drift")
      end

      row = %{"sha256" => canonical_sha256(report), "decision" => "accept"}
      row = if report["policy_id"], do: Map.put(row, "policy_id", report["policy_id"]), else: row
      {category, row}
    end)
  end

  defp accepted?("reachability", report, _),
    do: report["status"] == "complete" and is_list(report["modules"])

  defp accepted?("client_safety", report, _),
    do: report["status"] == "complete" and report["violations"] == []

  defp accepted?("compatibility", report, _),
    do:
      report["status"] == "complete" and report["compatible"] == true and
        report["violations"] == []

  defp accepted?("secret_audit", report, _),
    do: report["status"] == "complete" and report["clean"] == true and report["findings"] == []

  defp accepted?("license_inventory", report, _),
    do:
      report["status"] == "complete" and report["complete"] == true and report["components"] != []

  defp accepted?("bundle_plan", report, _),
    do: report["status"] == "complete" and report["complete"] == true and report["bundles"] != []

  defp accepted?("runtime_closure", report, _),
    do: report["status"] == "complete" and report["complete"] == true and report["outputs"] != []

  defp accepted?("payload", report, _),
    do:
      report["status"] == "complete" and report["complete"] == true and
        report["decision"] == "accept" and
        Enum.all?(report["budgets"], &(&1["result"] == "passed"))

  defp accepted?("delivery_integrity", report, manifest),
    do: report == manifest["delivery_integrity"] and report["algorithm"] == "sha384"

  defp accepted?(_, _, _), do: false

  defp canonical_sha256(value), do: value |> JSON.encode!() |> then(&sha256(&1 <> "\n"))
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  defp invalid!(id, message), do: raise(ArgumentError, "entrypoint attestation #{id}: #{message}")
end
