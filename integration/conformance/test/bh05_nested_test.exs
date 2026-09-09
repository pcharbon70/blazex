Code.require_file("../../bh-05/nested-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.NestedTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.NestedFixtures, as: F
  alias BlazeX.Component.NestedTable
  alias BlazeX.Renderer.{Context, Headless}

  test "public lifecycle script retains state and matches an independent headless oracle" do
    sessions = F.script()

    expected = [
      {["a", "b"], %{"a" => 0, "b" => 0}},
      {["a", "b"], %{"a" => 1, "b" => 0}},
      {["b", "a"], %{"a" => 1, "b" => 0}},
      {["a", "c"], %{"a" => 1, "c" => 7}}
    ]

    snapshots =
      Enum.zip(sessions, expected)
      |> Enum.map(fn {session, {order, states}} ->
        assert session.output == F.oracle(order, states)
        {:ok, context} = Context.new(session.table.root, session.table.revision, :mount)
        assert {:ok, _, actual} = Headless.mount(session.output, context)
        assert {:ok, _, ^actual} = Headless.mount(F.oracle(order, states), context)
        actual.value.digest
      end)

    assert [disposal] = List.last(sessions).disposals
    assert disposal.component == "b" and disposal.reason == :removed
    assert Enum.map(sessions, & &1.table.revision) == [1, 2, 3, 4]
    for _ <- 1..20, do: assert(F.script() == sessions)

    summary =
      Enum.map(sessions, &{&1.table.digest, &1.output_digest, &1.trace_digest, &1.disposals})

    IO.puts("NESTED_SCRIPT_SHA256 " <> NestedTable.digest(summary))
    IO.puts("NESTED_HEADLESS_SHA256 " <> NestedTable.digest(snapshots))
    IO.puts("NESTED_FINAL_STATE_SHA256 " <> List.last(sessions).table.digest)
  end

  test "all keyed permutations preserve local state and output order across repeated updates" do
    {:ok, initial} = F.mount()
    {:ok, initial} = F.increment(initial, "a")

    for order <- [["a", "b"], ["b", "a"]] do
      graph = put_in(F.graph(), ["group", :children], order)

      final =
        Enum.reduce(1..30, initial, fn _, before ->
          assert {:ok, after_move} = F.reconcile(before, graph)
          assert F.record(after_move, "a").state == {:present, 1}
          assert F.record(after_move, "b").state == {:present, 0}
          refute Enum.any?(after_move.trace, &(&1.event == :init))
          after_move
        end)

      assert final.output == F.oracle(order, %{"a" => 1, "b" => 0})
    end
  end

  test "parent-scope changes remove and insert instead of transplanting retained state" do
    graph =
      F.graph()
      |> put_in(["root", :children], ["group", "other"])
      |> Map.put("other", F.spec(BlazeX.BH05.NestedShell, "other"))

    {:ok, before} = F.mount(graph)
    {:ok, before} = F.increment(before, "a")
    moved = graph |> put_in(["group", :children], ["b"]) |> put_in(["other", :children], ["a"])
    assert {:ok, after_move} = F.reconcile(before, moved)
    assert F.record(after_move, "a").state == {:present, 0}
    assert F.record(after_move, "a").identity != F.record(before, "a").identity
    assert Enum.map(after_move.disposals, & &1.component) == ["a"]
  end

  test "retained state rejects ordinal slot identity and malformed props before callbacks" do
    root = %{
      F.spec(BlazeX.BH05.OrdinalSlot, "root")
      | slots: %{
          "default" => [
            %{"content" => %{"owner" => "nested", "caller" => "root", "id" => "counter"}}
          ]
        }
    }

    graph = %{"root" => root, "counter" => F.spec(BlazeX.BH05.NestedCounter, "counter")}
    assert {:error, %{code: :unstable_key}} = F.mount(graph)

    assert {:error, %{code: :invocation}} =
             F.mount(put_in(F.graph(), ["a", :props], %{"seed" => "not-integer"}))

    assert {:error, _} = F.mount(put_in(F.graph(), ["a", :key], ""))
  end

  test "notification boundary and graph overflow reject without advancing the accepted table" do
    leaves = Map.new(1..127, fn n -> {"n#{n}", F.spec(BlazeX.BH05.NestedCounter, "n#{n}")} end)
    root = F.spec(BlazeX.BH05.NestedShell, "root", Enum.sort(Map.keys(leaves)))
    graph = Map.put(leaves, "root", root)
    assert {:ok, before} = F.mount(graph)

    changed =
      Map.new(graph, fn {ref, spec} ->
        {ref,
         if(ref == "root",
           do: spec,
           else: %{spec | props: %{"notices" => if(ref == "n1", do: 2, else: 1)}}
         )}
      end)

    assert {:ok, accepted} = F.reconcile(before, changed)
    assert length(accepted.notifications) == 128
    overflow = put_in(changed, ["n1", :props, "notices"], 3)
    assert {:error, %{code: :notification_limit}, ^before} = F.reconcile(before, overflow)

    assert {:error, %{code: :graph}, ^before} =
             F.reconcile(
               before,
               Map.put(graph, "excess", F.spec(BlazeX.BH05.NestedCounter, "excess"))
             )
  end

  test "counter overflow and accepted-table tampering fail closed" do
    {:ok, before} = F.mount()
    records = Enum.map(before.table.records, &%{&1 | revision: 9_007_199_254_740_991})
    {:ok, table} = NestedTable.new(before.table.root, 9_007_199_254_740_991, 0, records)
    full = %{before | table: table}
    assert {:error, %{code: :counter_overflow}, ^full} = F.reconcile(full, F.graph())
    corrupted = %{before | output_digest: String.duplicate("0", 64)}
    assert {:error, %{code: :prior}, ^corrupted} = F.reconcile(corrupted, F.graph())
    bad_graph = %{before | graph: put_in(F.graph(), ["a", :props], %{"seed" => 100})}
    assert {:error, %{code: :prior}, ^bad_graph} = F.reconcile(bad_graph, F.graph())
    refute_received _
  end
end
