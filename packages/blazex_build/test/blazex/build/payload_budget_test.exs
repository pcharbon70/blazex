defmodule BlazeX.Build.PayloadBudgetTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.{PayloadBudget, PayloadPolicy}

  setup do
    root = Path.join(System.tmp_dir!(), "payload-budget-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, "assets"))
    File.mkdir_p!(Path.join(root, "evidence"))
    File.write!(Path.join(root, "assets/feature.avm"), "feature bytes")
    File.write!(Path.join(root, "evidence/report.json"), "{}")

    manifest = %{
      "artifacts" => [
        %{
          "path" => "assets/feature.avm",
          "role" => "feature-bundle",
          "exposure" => "public",
          "bytes" => 13,
          "sha256" => digest("feature bytes")
        },
        %{
          "path" => "evidence/report.json",
          "role" => "reachability-report",
          "exposure" => "private-build-evidence",
          "bytes" => 2,
          "sha256" => digest("{}")
        }
      ]
    }

    File.write!(Path.join(root, "build-manifest.json"), "manifest")
    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, manifest: manifest}
  end

  test "writes deterministic sidecars and accepts a passing candidate", %{
    root: root,
    manifest: manifest
  } do
    report = PayloadBudget.measure!(manifest, root, policy(1_000), &samples/2)
    assert report["decision"] == "accept"

    assert report["summary"] == %{
             "manifest_artifacts" => 2,
             "public_artifacts" => 2,
             "private_artifacts" => 1,
             "public_decoded_bytes" => 21,
             "public_brotli_bytes" => 21,
             "public_source_maps" => 0,
             "failed_budgets" => 0
           }

    assert File.read!(Path.join(root, "assets/feature.avm.br")) == "feature bytes"
  end

  test "records a failed budget without suppressing measurements", %{
    root: root,
    manifest: manifest
  } do
    report = PayloadBudget.measure!(manifest, root, policy(1), &samples/2)
    assert report["decision"] == "reject"

    assert [%{"id" => "application-brotli", "observed" => 21, "result" => "failed"}] =
             report["budgets"]
  end

  test "rejects identity, exposure, undeclared-file, and compression drift", %{
    root: root,
    manifest: manifest
  } do
    assert_raise ArgumentError, ~r/identity drift/, fn ->
      PayloadBudget.measure!(
        put_in(manifest, ["artifacts", Access.at(0), "bytes"], 12),
        root,
        policy(1_000),
        &samples/2
      )
    end

    assert_raise ArgumentError, ~r/exposure drift/, fn ->
      PayloadBudget.measure!(
        put_in(manifest, ["artifacts", Access.at(0), "exposure"], "private-build-evidence"),
        root,
        policy(1_000),
        &samples/2
      )
    end

    File.write!(Path.join(root, "stray.map"), "map")

    assert_raise ArgumentError, ~r/undeclared files/, fn ->
      PayloadBudget.measure!(manifest, root, policy(1_000), &samples/2)
    end

    File.rm!(Path.join(root, "stray.map"))

    assert_raise ArgumentError, ~r/nondeterministic/, fn ->
      PayloadBudget.measure!(manifest, root, policy(1_000), fn path, _ ->
        [File.read!(path), "different", File.read!(path)]
      end)
    end
  end

  defp samples(path, %{"repetitions" => count}), do: List.duplicate(File.read!(path), count)
  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp policy(threshold) do
    value = BlazeX.Build.PayloadPolicyTest.policy()
    PayloadPolicy.new!(put_in(value, ["budgets", Access.at(0), "threshold"], threshold))
  end
end
