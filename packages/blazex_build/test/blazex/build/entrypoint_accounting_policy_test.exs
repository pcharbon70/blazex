defmodule BlazeX.Build.EntryPointAccountingPolicyTest do
  use ExUnit.Case, async: false
  alias BlazeX.Build.EntryPointAccountingPolicy

  test "loads an ordered closed policy without creating atoms" do
    EntryPointAccountingPolicy.new!(policy())
    before = :erlang.system_info(:atom_count)

    loaded =
      EntryPointAccountingPolicy.new!(
        put_in(policy()["entrypoints"], [
          %{"id" => "untrusted-123", "module" => "Untrusted.Module123"}
        ])
      )

    assert loaded.entrypoints |> hd() |> Map.fetch!("id") == "untrusted-123"
    assert :erlang.system_info(:atom_count) == before
  end

  test "rejects duplicates, disorder, unknown evidence, overlap, and limits" do
    assert_raise ArgumentError, fn ->
      EntryPointAccountingPolicy.new!(
        put_in(policy()["entrypoints"], policy()["entrypoints"] ++ policy()["entrypoints"])
      )
    end

    assert_raise ArgumentError, fn ->
      EntryPointAccountingPolicy.new!(
        put_in(policy()["required_public_roles"], ["runtime-wasm", "document"])
      )
    end

    assert_raise ArgumentError, fn ->
      EntryPointAccountingPolicy.new!(put_in(policy()["required_evidence"], ["unknown"]))
    end

    assert_raise ArgumentError, fn ->
      EntryPointAccountingPolicy.new!(put_in(policy()["required_private_roles"], ["document"]))
    end

    assert_raise ArgumentError, fn ->
      EntryPointAccountingPolicy.new!(put_in(policy()["limits"]["max_entrypoints"], 0))
    end
  end

  defp policy do
    %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.accounting/1",
      "entrypoints" => [%{"id" => "counter", "module" => "Elixir.Counter"}],
      "required_public_roles" => ["document"],
      "required_private_roles" => [
        "bundle-plan-report",
        "client-safety-report",
        "compatibility-report",
        "license-inventory-report",
        "reachability-report",
        "runtime-closure-report",
        "secret-audit-report"
      ],
      "required_evidence" => [
        "bundle_plan",
        "client_safety",
        "compatibility",
        "delivery_integrity",
        "license_inventory",
        "payload",
        "reachability",
        "runtime_closure",
        "secret_audit"
      ],
      "limits" => %{
        "max_entrypoints" => 2,
        "max_artifacts" => 16,
        "max_evidence_categories" => 16
      }
    }
  end
end
