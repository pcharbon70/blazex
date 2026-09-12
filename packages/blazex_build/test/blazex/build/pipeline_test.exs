defmodule BlazeX.Build.PipelineTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.{EntryPoint, Pipeline}

  setup do
    root = Path.join(System.tmp_dir!(), "blazex-build-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    files =
      for {name, body} <- [
            {"bundle.avm", "bundle"},
            {"AtomVM.mjs", "module"},
            {"AtomVM.wasm", "wasm"},
            {"host.js", "host"},
            {"index.html", "<script type=module src=\"{{HOST_ASSET}}\"></script>"}
          ],
          into: %{} do
        path = Path.join(root, name)
        File.write!(path, body)
        {name, path}
      end

    spec =
      EntryPoint.new!(%{
        id: "counter",
        module: "Elixir.BlazeX.BH06.Slice.Counter",
        bundle: files["bundle.avm"],
        runtime_module: files["AtomVM.mjs"],
        runtime_wasm: files["AtomVM.wasm"],
        host: files["host.js"],
        document: files["index.html"],
        compatibility: %{"runtime" => "atomvm-wasm/0.6"}
      })

    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, spec: spec}
  end

  test "builds byte-equivalent manifests and content-addressed assets", %{root: root, spec: spec} do
    one = Path.join(root, "one")
    two = Path.join(root, "two")
    Pipeline.build!(spec, one)
    Pipeline.build!(spec, two)

    assert File.read!(Path.join(one, "build-manifest.json")) ==
             File.read!(Path.join(two, "build-manifest.json"))

    assert inventory(one) == inventory(two)
    assert :ok = Pipeline.verify!(one)
  end

  test "binds a content-addressed reachability report", %{root: root, spec: spec} do
    output = Path.join(root, "reachability")
    report = %{"schema_version" => "1.0.0", "modules" => [%{"module" => spec.module}]}
    manifest = Pipeline.build!(spec, output, reachability: report)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "reachability-report"))
    assert String.contains?(asset["path"], asset["sha256"])
    assert String.starts_with?(asset["path"], "evidence/")
    assert asset["exposure"] == "private-build-evidence"

    assert File.read!(Path.join(output, asset["path"])) ==
             BlazeX.Build.JSON.encode!(report) <> "\n"

    assert :ok = Pipeline.verify!(output)
    File.write!(Path.join(output, asset["path"]), "{}\n")

    assert_raise ArgumentError, ~r/integrity mismatch/, fn ->
      Pipeline.verify!(output)
    end
  end

  test "binds a content-addressed client-safety report", %{root: root, spec: spec} do
    output = Path.join(root, "client-safety")
    report = %{"schema_version" => "1.0.0", "policy_id" => "test.policy/1"}
    manifest = Pipeline.build!(spec, output, client_safety: report)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "client-safety-report"))
    assert String.contains?(asset["path"], asset["sha256"])

    assert File.read!(Path.join(output, asset["path"])) ==
             BlazeX.Build.JSON.encode!(report) <> "\n"

    assert :ok = Pipeline.verify!(output)
    File.write!(Path.join(output, asset["path"]), "{}\n")
    assert_raise ArgumentError, ~r/integrity mismatch/, fn -> Pipeline.verify!(output) end
  end

  test "binds only a passing compatibility report and its exact identities", %{
    root: root,
    spec: spec
  } do
    output = Path.join(root, "compatibility")

    report = %{
      "schema_version" => "1.0.0",
      "compatible" => true,
      "profile_id" => "test.profile/1",
      "profile_sha256" => String.duplicate("a", 64),
      "requirement_id" => "test.requirements/1",
      "requirements_sha256" => String.duplicate("b", 64)
    }

    manifest = Pipeline.build!(spec, output, compatibility: report)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "compatibility-report"))
    assert String.contains?(asset["path"], asset["sha256"])

    assert manifest["compatibility"] == %{
             "profile_id" => "test.profile/1",
             "profile_sha256" => String.duplicate("a", 64),
             "requirement_id" => "test.requirements/1",
             "requirements_sha256" => String.duplicate("b", 64)
           }

    assert_raise ArgumentError, ~r/passing bound report/, fn ->
      Pipeline.build!(spec, Path.join(root, "rejected"),
        compatibility: %{report | "compatible" => false}
      )
    end
  end

  test "rejects changed assets and mutable output", %{root: root, spec: spec} do
    output = Path.join(root, "output")
    manifest = Pipeline.build!(spec, output)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "application-bundle"))
    File.write!(Path.join(output, asset["path"]), "changed")
    assert_raise ArgumentError, ~r/integrity mismatch/, fn -> Pipeline.verify!(output) end
    assert_raise ArgumentError, ~r/absent or empty/, fn -> Pipeline.build!(spec, output) end
  end

  test "binds a content-addressed clean secret audit", %{root: root, spec: spec} do
    report = %{"schema_version" => "1.0.0", "clean" => true, "policy_id" => "test/1"}
    output = Path.join(root, "secret-audit")
    manifest = Pipeline.build!(spec, output, secret_audit: report)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "secret-audit-report"))
    assert String.contains?(asset["path"], asset["sha256"])

    assert File.read!(Path.join(output, asset["path"])) ==
             BlazeX.Build.JSON.encode!(report) <> "\n"
  end

  test "binds a content-addressed complete license inventory", %{root: root, spec: spec} do
    report = %{"schema_version" => "1.0.0", "complete" => true, "policy_id" => "test/1"}
    output = Path.join(root, "license-inventory")
    manifest = Pipeline.build!(spec, output, license_inventory: report)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "license-inventory-report"))
    assert String.contains?(asset["path"], asset["sha256"])

    assert File.read!(Path.join(output, asset["path"])) ==
             BlazeX.Build.JSON.encode!(report) <> "\n"
  end

  test "binds ordered content-addressed feature bundles and plan", %{root: root, spec: spec} do
    counter = Path.join(root, "counter.avm")
    File.write!(counter, "feature")
    plan = %{"schema_version" => "1.0.0", "complete" => true}

    manifest =
      Pipeline.build!(spec, Path.join(root, "features"),
        bundle_plan: plan,
        feature_bundles: [%{"id" => "counter", "path" => counter}]
      )

    assert %{"feature_id" => "counter", "role" => "feature-bundle", "path" => path} =
             Enum.find(manifest["artifacts"], &(&1["role"] == "feature-bundle"))

    assert String.starts_with?(path, "assets/feature-counter-")

    assert Enum.find(manifest["artifacts"], &(&1["role"] == "feature-bundle"))["exposure"] ==
             "public"

    assert Enum.any?(manifest["artifacts"], &(&1["role"] == "bundle-plan-report"))

    assert_raise ArgumentError, ~r/duplicate feature/, fn ->
      Pipeline.build!(spec, Path.join(root, "duplicate-features"),
        feature_bundles: [
          %{"id" => "counter", "path" => counter},
          %{"id" => "counter", "path" => counter}
        ]
      )
    end
  end

  test "rejects malformed entrypoints and document templates", %{spec: spec} do
    assert_raise ArgumentError, ~r/lowercase/, fn -> EntryPoint.new!(%{spec | id: "Bad ID"}) end
    path = Path.join(Path.dirname(spec.document), "bad.html")
    File.write!(path, "no host placeholder")
    output = Path.join(Path.dirname(spec.document), "bad-output")

    assert_raise ArgumentError, ~r/HOST_ASSET/, fn ->
      Pipeline.build!(%{spec | document: path}, output)
    end
  end

  defp inventory(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(fn path -> {Path.relative_to(path, root), File.read!(path)} end)
    |> Enum.sort()
  end
end
