defmodule BlazeX.Build.BeamInventoryTest do
  use ExUnit.Case, async: false

  alias BlazeX.Build.{BeamInventory, ClientEntryPoint}

  setup_all do
    root = Path.join(System.tmp_dir!(), "blazex-beams-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    modules =
      Code.compile_string("""
      defmodule BlazeX.Build.Fixture.Leaf do
        @moduledoc false
        def value, do: 1
      end

      defmodule BlazeX.Build.Fixture.Root do
        def value, do: BlazeX.Build.Fixture.Leaf.value()
      end
      """)

    paths =
      Enum.map(modules, fn {module, binary} ->
        path = Path.join(root, Atom.to_string(module) <> ".beam")
        File.write!(path, binary)
        path
      end)

    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, paths: paths}
  end

  test "validates entrypoints without converting strings to atoms" do
    module = "Elixir.BH06NeverIntern#{System.unique_integer([:positive])}"
    assert_raise ArgumentError, fn -> String.to_existing_atom(module) end
    entry = ClientEntryPoint.new!(%{id: "main", module: module})
    assert entry.module == module
    assert_raise ArgumentError, fn -> String.to_existing_atom(module) end

    assert_raise ArgumentError, ~r/lowercase/, fn ->
      ClientEntryPoint.new!(%{id: "Bad", module: "BlazeX.Build.Fixture.Root"})
    end
  end

  test "normalizes BEAM facts independent of input order and paths", %{paths: paths} do
    forward = BeamInventory.scan!(paths)
    reverse = BeamInventory.scan!(Enum.reverse(paths))
    assert forward == reverse
    refute inspect(forward) =~ System.tmp_dir!()

    root = Enum.find(forward, &String.ends_with?(&1["module"], ".Root"))

    assert %{"module" => "Elixir.BlazeX.Build.Fixture.Leaf", "function" => "value", "arity" => 0} in root[
             "imports"
           ]

    assert %{"function" => "value", "arity" => 0} in root["exports"]
    assert Enum.all?(forward, &Regex.match?(~r/^[0-9a-f]{64}$/, &1["sha256"]))
  end

  test "rejects duplicate modules and malformed BEAMs", %{root: root, paths: [first | _]} do
    duplicate = Path.join(root, "duplicate.beam")
    File.cp!(first, duplicate)

    assert_raise ArgumentError, ~r/duplicate BEAM modules/, fn ->
      BeamInventory.scan!([first, duplicate])
    end

    malformed = Path.join(root, "malformed.beam")
    File.write!(malformed, "not a BEAM")
    assert_raise ArgumentError, ~r/malformed BEAM/, fn -> BeamInventory.scan!([malformed]) end
  end
end
