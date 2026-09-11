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

  test "rejects changed assets and mutable output", %{root: root, spec: spec} do
    output = Path.join(root, "output")
    manifest = Pipeline.build!(spec, output)
    asset = Enum.find(manifest["artifacts"], &(&1["role"] == "application-bundle"))
    File.write!(Path.join(output, asset["path"]), "changed")
    assert_raise ArgumentError, ~r/integrity mismatch/, fn -> Pipeline.verify!(output) end
    assert_raise ArgumentError, ~r/absent or empty/, fn -> Pipeline.build!(spec, output) end
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
