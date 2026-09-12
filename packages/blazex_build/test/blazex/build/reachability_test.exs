defmodule BlazeX.Build.ReachabilityTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{ClientEntryPoint, Reachability}

  @root %{
    "module" => "Elixir.App.Root",
    "sha256" => String.duplicate("a", 64),
    "imports" => [
      %{"module" => "Elixir.App.Leaf", "function" => "value", "arity" => 0},
      %{"module" => "erlang", "function" => "+", "arity" => 2}
    ]
  }
  @leaf %{
    "module" => "Elixir.App.Leaf",
    "sha256" => String.duplicate("b", 64),
    "imports" => [%{"module" => "Elixir.App.Root", "function" => "value", "arity" => 0}]
  }
  @unused %{
    "module" => "Elixir.App.Unused",
    "sha256" => String.duplicate("c", 64),
    "imports" => []
  }

  test "returns stable rooted reason chains, cycles, externals, and unused modules" do
    entry = ClientEntryPoint.new!(%{id: "main", module: "App.Root"})
    one = Reachability.analyze!([entry], [@unused, @leaf, @root])
    two = Reachability.analyze!([entry], [@root, @leaf, @unused])
    assert one == two
    assert Enum.map(one["modules"], & &1["module"]) == ["Elixir.App.Leaf", "Elixir.App.Root"]

    assert Enum.find(one["modules"], &(&1["module"] == "Elixir.App.Leaf"))["reason_chain"] == [
             "Elixir.App.Root",
             "Elixir.App.Leaf"
           ]

    assert one["unused_modules"] == ["Elixir.App.Unused"]

    assert one["summary"] == %{
             "dynamic_allowances" => 0,
             "entrypoints" => 1,
             "external_references" => 1,
             "inventory_modules" => 3,
             "known_edges" => 2,
             "reachable_modules" => 2,
             "unused_modules" => 1
           }
  end

  test "rejects missing and duplicate roots" do
    missing = ClientEntryPoint.new!(%{id: "missing", module: "App.Missing"})

    assert_raise ArgumentError, ~r/missing from inventory/, fn ->
      Reachability.analyze!([missing], [@root])
    end

    root = ClientEntryPoint.new!(%{id: "main", module: "App.Root"})
    alias_root = ClientEntryPoint.new!(%{id: "alias", module: "App.Root"})

    assert_raise ArgumentError, ~r/duplicate entrypoint modules/, fn ->
      Reachability.analyze!([root, alias_root], [@root])
    end
  end

  test "requires an exact bounded allowance for dynamic apply" do
    dynamic =
      put_in(@root["imports"], [%{"module" => "erlang", "function" => "apply", "arity" => 3}])

    entry = ClientEntryPoint.new!(%{id: "main", module: "App.Root"})

    assert_raise ArgumentError, ~r/undeclared dynamic dispatch/, fn ->
      Reachability.analyze!([entry], [dynamic])
    end

    report =
      Reachability.analyze!([entry], [dynamic],
        allow_dynamic: %{"Elixir.App.Root" => "closed registry dispatch"}
      )

    assert [%{"reason" => "closed registry dispatch"}] =
             Enum.map(report["dynamic_allowances"], &Map.take(&1, ["reason"]))

    assert_raise ArgumentError, ~r/unused dynamic allowances/, fn ->
      Reachability.analyze!([entry], [@root, @leaf],
        allow_dynamic: %{"Elixir.App.Root" => "stale"}
      )
    end
  end

  test "chooses the shortest lexical reason when roots converge" do
    other = %{@root | "module" => "Elixir.App.Other", "imports" => [hd(@root["imports"])]}

    entries = [
      ClientEntryPoint.new!(%{id: "zeta", module: "App.Root"}),
      ClientEntryPoint.new!(%{id: "alpha", module: "App.Other"})
    ]

    report = Reachability.analyze!(entries, [@root, other, @leaf, @unused])
    leaf = Enum.find(report["modules"], &(&1["module"] == "Elixir.App.Leaf"))
    assert leaf["entrypoint"] == "alpha"
    assert leaf["reason_chain"] == ["Elixir.App.Other", "Elixir.App.Leaf"]
  end
end
