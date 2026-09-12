defmodule BlazeX.Build.EntryPointAttestationTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.{EntryPointAccountingPolicy, EntryPointAttestation, JSON}

  setup do
    reports = reports()

    private_roles = %{
      "bundle_plan" => "bundle-plan-report",
      "client_safety" => "client-safety-report",
      "compatibility" => "compatibility-report",
      "license_inventory" => "license-inventory-report",
      "reachability" => "reachability-report",
      "runtime_closure" => "runtime-closure-report",
      "secret_audit" => "secret-audit-report"
    }

    private_artifacts =
      Enum.map(private_roles, fn {category, role} ->
        hash = reports[category] |> JSON.encode!() |> then(&digest(&1 <> "\n"))
        artifact("evidence/#{category}.json", role, "private-build-evidence", hash)
      end)

    manifest = %{
      "schema_version" => "1.0.0",
      "manifest_id" => "test/1",
      "support_state" => "unsupported",
      "entrypoint" => %{"id" => "counter", "module" => "Elixir.Counter"},
      "delivery_integrity" => reports["delivery_integrity"],
      "artifacts" => [
        artifact("index.html", "document", "public", digest("doc")) | private_artifacts
      ]
    }

    policy =
      EntryPointAccountingPolicy.new!(%{
        "schema_version" => "1.0.0",
        "policy_id" => "test.accounting/1",
        "entrypoints" => [%{"id" => "counter", "module" => "Elixir.Counter"}],
        "required_public_roles" => ["document"],
        "required_private_roles" => Enum.sort(Map.values(private_roles)),
        "required_evidence" => Enum.sort(Map.keys(reports)),
        "limits" => %{
          "max_entrypoints" => 2,
          "max_artifacts" => 16,
          "max_evidence_categories" => 16
        }
      })

    %{manifest: manifest, reports: reports, policy: policy}
  end

  test "builds and verifies byte-equivalent complete accounting", c do
    one = EntryPointAttestation.build!(c.manifest, c.reports, c.policy)
    two = EntryPointAttestation.build!(c.manifest, c.reports, c.policy)
    assert one == two
    assert one["decision"] == "accept"

    assert one["summary"] == %{
             "artifacts" => 8,
             "public_artifacts" => 1,
             "private_artifacts" => 7,
             "shipped_components" => 1,
             "license_records" => 1,
             "public_decoded_bytes" => 3,
             "public_brotli_bytes" => 2,
             "failed_budgets" => 0
           }

    assert :ok = EntryPointAttestation.verify!(one, c.manifest, c.reports, c.policy)
    assert :ok = EntryPointAttestation.assert_complete_set!([one], c.policy)
  end

  test "rejects missing categories, undeclared roots, rejected evidence, identity drift, and incomplete sets",
       c do
    assert_raise ArgumentError, ~r/categories/, fn ->
      EntryPointAttestation.build!(c.manifest, Map.delete(c.reports, "payload"), c.policy)
    end

    assert_raise ArgumentError, ~r/undeclared/, fn ->
      EntryPointAttestation.build!(
        %{c.manifest | "entrypoint" => Map.put(c.manifest["entrypoint"], "id", "other")},
        c.reports,
        c.policy
      )
    end

    assert_raise ArgumentError, ~r/payload decision/, fn ->
      changed_reports =
        %{c.reports | "payload" => Map.put(c.reports["payload"], "decision", "reject")}

      EntryPointAttestation.build!(
        c.manifest,
        changed_reports,
        c.policy
      )
    end

    assert_raise ArgumentError, ~r/identity drift/, fn ->
      changed =
        List.update_at(
          c.manifest["artifacts"],
          -1,
          &Map.put(&1, "sha256", String.duplicate("0", 64))
        )

      EntryPointAttestation.build!(
        %{c.manifest | "artifacts" => changed},
        c.reports,
        c.policy
      )
    end

    assert_raise ArgumentError, ~r/does not match/, fn ->
      EntryPointAttestation.assert_complete_set!([], c.policy)
    end
  end

  defp reports do
    %{
      "reachability" => %{"status" => "complete", "modules" => []},
      "client_safety" => %{"status" => "complete", "violations" => []},
      "compatibility" => %{"status" => "complete", "compatible" => true, "violations" => []},
      "secret_audit" => %{"status" => "complete", "clean" => true, "findings" => []},
      "license_inventory" => %{
        "status" => "complete",
        "complete" => true,
        "components" => [%{"id" => "app"}],
        "summary" => %{"shipped_components" => 1, "license_records" => 1}
      },
      "bundle_plan" => %{
        "status" => "complete",
        "complete" => true,
        "bundles" => [%{"id" => "base"}]
      },
      "runtime_closure" => %{
        "status" => "complete",
        "complete" => true,
        "outputs" => [%{"module" => "app"}]
      },
      "payload" => %{
        "status" => "complete",
        "complete" => true,
        "decision" => "accept",
        "budgets" => [%{"result" => "passed"}],
        "summary" => %{
          "public_decoded_bytes" => 3,
          "public_brotli_bytes" => 2,
          "failed_budgets" => 0
        }
      },
      "delivery_integrity" => %{
        "algorithm" => "sha384",
        "manifest_cache_control" => "no-store",
        "policy_id" => "test.delivery/1",
        "policy_sha256" => String.duplicate("a", 64)
      }
    }
  end

  defp artifact(path, role, exposure, hash),
    do: %{
      "path" => path,
      "role" => role,
      "exposure" => exposure,
      "sha256" => hash,
      "integrity" => "sha384-" <> String.duplicate("A", 64),
      "bytes" => 3,
      "cache_control" => "no-store"
    }

  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
