defmodule BlazeX.NestedTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.Event
  alias BlazeX.UITree.Nested
  alias BlazeX.Component.NestedTable
  @boundary %{kind: :local, root: "root", owner: "root"}

  defmodule Shell do
    use BlazeX.Component, role: :pure, schema: [props: [], slots: []]
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule OtherShell do
    use BlazeX.Component, role: :pure, schema: [props: [], slots: []]
    def render(_), do: {:output, {:semantic, 1, %{kind: :surface}}}
  end

  defmodule Counter do
    use BlazeX.Component,
      role: :stateful,
      schema: [
        props: [
          {"seed", [type: :integer, default: 0]},
          {"mode", [type: :integer, default: 0]}
        ],
        slots: []
      ]

    def init(%{props: %{"seed" => seed, "mode" => mode}}) do
      case mode do
        1 -> {:state, %{resource: "PRIVATE"}}
        2 -> {:rejected, :failed}
        3 -> :erlang.error(:private_failure)
        _ -> {:state, seed}
      end
    end

    def update(%{props: %{"mode" => mode}}) do
      case mode do
        7 -> {:state, %{resource: "PRIVATE"}}
        8 -> :erlang.error(:private_failure)
        _ -> :no_change
      end
    end

    def handle_event(%{state: {:present, state}, props: %{"mode" => mode}}) do
      case mode do
        5 ->
          {:actions, state + 1, [{:effect, "clock", %{}}]}

        10 ->
          {:actions, state + 1,
           [{:message, "parent", %{name: :change, payload: %{value: state + 1}}}]}

        _ ->
          {:state, state + 1}
      end
    end

    def render(%{state: {:present, state}, props: %{"mode" => mode}}) do
      if mode == 4 do
        {:output, {:semantic, 1, %{kind: :not_semantic}}}
      else
        {:output,
         {:semantic, 1,
          %{
            kind: :group,
            bindings: [:increment],
            accessibility: %{role: :group, name: Integer.to_string(state)}
          }}}
      end
    end

    def dispose(%{props: %{"mode" => mode}}),
      do: if(mode == 6, do: {:rejected, :failed}, else: :ok)
  end

  defmodule Replacement do
    use BlazeX.Component,
      role: :stateful,
      schema: [props: [{"value", [type: :integer, default: 99]}], slots: []]

    def init(%{props: %{"value" => value}}), do: {:state, value}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group, bindings: [:increment]}}}
  end

  def spec(module, id, children \\ [], props \\ %{}),
    do: %{
      module: module,
      public_id: id,
      site: "site",
      key: id,
      props: props,
      slots: %{},
      children: children
    }

  def graph,
    do: %{
      "root" => spec(Shell, "root", ["a", "b"]),
      "a" => spec(Counter, "a"),
      "b" => spec(Counter, "b")
    }

  def mount(graph \\ graph()), do: Nested.mount("root", 1, "root", graph, @boundary)
  def record(session, id), do: Enum.find(session.table.records, &(&1.public_id == id))

  def event(session, id, sequence \\ nil) do
    {:ok, event} =
      Event.new(
        :increment,
        session.table.root,
        record(session, id).identity,
        %{},
        sequence || session.table.sequence + 1
      )

    event
  end

  def reconcile(session, graph, generation \\ 1, replacements \\ []),
    do: Nested.reconcile(session, session.table.revision, generation, "root", graph, replacements)

  test "local event commits state and output together, then keyed reorder retains local state" do
    assert {:ok, before} = mount()
    assert {:ok, changed} = Nested.event(before, 1, event(before, "a"))
    assert record(changed, "a").state == {:present, 1}
    assert record(before, "a").state == {:present, 0}
    assert changed.table.revision == 2 and changed.table.sequence == 1
    reordered = put_in(graph(), ["root", :children], ["b", "a"])
    assert {:ok, after_move} = reconcile(changed, reordered)
    assert Enum.map(after_move.table.records, & &1.public_id) == ["root", "b", "a"]
    assert record(after_move, "a").state == {:present, 1}
    refute Enum.any?(after_move.trace, &(&1.event == :init))
    assert after_move.disposals == []
    props = put_in(reordered, ["a", :props], %{"seed" => 200})
    assert {:ok, updated} = reconcile(after_move, props)
    assert record(updated, "a").state == {:present, 1}
    assert {:ok, noop} = reconcile(updated, props)
    assert noop.table.revision == updated.table.revision + 1
    assert noop.output_digest == updated.output_digest
  end

  test "insertions initialize and nested removals dispose deepest first" do
    graph =
      graph() |> put_in(["a", :children], ["child"]) |> Map.put("child", spec(Counter, "child"))

    assert {:ok, before} = mount(graph)

    next =
      graph
      |> Map.drop(["a", "child"])
      |> put_in(["root", :children], ["b", "new"])
      |> Map.put("new", spec(Counter, "new", [], %{"seed" => 8}))

    assert {:ok, after_remove} = reconcile(before, next)
    assert Enum.map(after_remove.disposals, & &1.component) == ["child", "a"]

    assert Enum.all?(
             after_remove.disposals,
             &(&1.reason == :removed and &1.callback == :accepted)
           )

    assert record(after_remove, "new").state == {:present, 8}
    assert NestedTable.valid?(before.table)
  end

  test "same-identity module/schema replacement needs authorization and initializes fresh" do
    assert {:ok, before} = mount()
    next = put_in(graph(), ["a", :module], Replacement)
    assert {:error, %{code: :replacement_required}, ^before} = reconcile(before, next)
    path = record(before, "a").identity.path
    assert {:ok, replaced} = reconcile(before, next, 1, [path])
    assert record(replaced, "a").state == {:present, 99}
    assert hd(replaced.disposals).reason == :replaced
    assert {:error, %{code: :replacement_paths}, ^before} = reconcile(before, graph(), 1, [path])
    parent = put_in(graph(), ["root", :module], OtherShell)
    assert {:ok, replaced_parent} = reconcile(before, parent, 1, [[]])
    assert length(replaced_parent.disposals) == 2
    assert Enum.count(replaced_parent.trace, &(&1.event == :init)) == 2
  end

  test "generation replacement drops retained state and old events without crossing roots" do
    assert {:ok, before} = mount()
    assert {:ok, changed} = Nested.event(before, 1, event(before, "a"))
    assert {:ok, replaced} = reconcile(changed, graph(), 2)
    assert record(replaced, "a").state == {:present, 0}
    assert Enum.all?(replaced.disposals, &(&1.reason == :generation))

    assert {:error, %{code: :event}, ^replaced} =
             Nested.event(replaced, replaced.table.revision, event(before, "a"))

    assert {:error, %{code: :generation}, ^replaced} = reconcile(replaced, graph(), 1)
    foreign = %{event(replaced, "a") | owner: %{replaced.table.root | root: "foreign"}}
    assert {:error, _, ^replaced} = Nested.event(replaced, replaced.table.revision, foreign)
  end

  test "callback failures invalid state semantic failure and duplicate identities roll back exactly" do
    assert {:ok, before} = mount()

    for mode <- [4, 7, 8] do
      assert {:error, diagnostic, ^before} =
               reconcile(before, put_in(graph(), ["a", :props], %{"mode" => mode}))

      refute inspect(diagnostic) =~ "PRIVATE"
      refute Map.has_key?(diagnostic, :output)
    end

    for mode <- [1, 2, 3] do
      assert {:error, diagnostic} = mount(put_in(graph(), ["a", :props], %{"mode" => mode}))
      refute inspect(diagnostic) =~ "private"
    end

    assert {:error, %{code: :duplicate_identity}, ^before} =
             reconcile(before, put_in(graph(), ["root", :children], ["a", "a", "b"]))

    assert {:error, %{code: :stale_revision}, ^before} =
             Nested.reconcile(before, 0, 1, "root", graph())

    assert {:error, %{code: :stale_event}, ^before} =
             Nested.event(before, 1, event(before, "a", 2))
  end

  test "typed parent notification is data only and prohibited effects cannot advance state" do
    for {mode, outcome} <- [{5, :error}, {10, :ok}] do
      assert {:ok, before} = mount(put_in(graph(), ["a", :props], %{"mode" => mode}))

      case outcome do
        :error ->
          assert {:error, %{code: :prohibited_action}, ^before} =
                   Nested.event(before, 1, event(before, "a"))

        :ok ->
          assert {:ok, after_event} = Nested.event(before, 1, event(before, "a"))
          assert [notice] = after_event.notifications
          assert notice.target == before.table.root and notice.name == :change
          assert notice.payload == %{value: 1}
          assert Enum.all?(after_event.table.records, &(&1.owned_actions == []))
          refute_received _
      end
    end
  end

  test "disposal rejection cannot publish candidate state or output" do
    assert {:ok, before} = mount(put_in(graph(), ["a", :props], %{"mode" => 6}))
    next = graph() |> Map.delete("a") |> put_in(["root", :children], ["b"])
    assert {:error, %{code: :callback_rejected}, ^before} = reconcile(before, next)
    assert before.disposals == []
  end

  test "complete transition traces and state/output digests repeat exactly" do
    script = fn ->
      {:ok, first} = mount()
      {:ok, second} = Nested.event(first, 1, event(first, "a"))
      {:ok, third} = reconcile(second, put_in(graph(), ["root", :children], ["b", "a"]))
      {first, second, third}
    end

    expected = script.()
    for _ <- 1..20, do: assert(script.() == expected)
    {_, _, last} = expected
    refute inspect(last.trace) =~ "BlazeX.NestedTest"
    refute inspect(last.trace) =~ "seed"
  end
end
