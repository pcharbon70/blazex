defmodule BlazeX.BH05.NestedShell do
  use BlazeX.Component,
    role: :pure,
    schema: [
      props: [{"kind", [type: {:enum, ["surface", "group", "text"]}, default: "group"]}],
      slots: []
    ]

  def render(%{props: %{"kind" => kind}}) do
    output =
      case kind do
        "surface" -> %{kind: :surface}
        "group" -> %{kind: :group}
        "text" -> %{kind: :text, content: "Count"}
      end

    {:output, {:semantic, 1, output}}
  end
end

defmodule BlazeX.BH05.NestedCounter do
  use BlazeX.Component,
    role: :stateful,
    schema: [
      props: [
        {"seed", [type: :integer, default: 0]},
        {"notices", [type: {:integer, 0, 3}, default: 0]}
      ],
      slots: []
    ]

  def init(%{props: %{"seed" => seed}}), do: {:state, seed}

  def update(%{state: {:present, state}, props: %{"notices" => count}}) do
    if count == 0,
      do: :no_change,
      else:
        {:actions, state,
         List.duplicate({:message, "parent", %{name: :change, payload: %{value: state}}}, count)}
  end

  def handle_event(%{state: {:present, state}}), do: {:state, state + 1}

  def render(%{state: {:present, state}}),
    do:
      {:output,
       {:semantic, 1,
        %{
          kind: :action,
          bindings: [:increment],
          accessibility: %{role: :button, name: Integer.to_string(state)}
        }}}

  def dispose(_), do: :ok
end

defmodule BlazeX.BH05.OrdinalSlot do
  use BlazeX.Component,
    role: :pure,
    schema: [props: [], slots: [{"default", [key: :optional]}]]

  def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
end

defmodule BlazeX.BH05.NestedFixtures do
  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.UITree.{Accessibility, Binding, Document, IntentSet, Nested, Node}
  def boundary, do: %{kind: :local, root: "nested", owner: "nested"}

  def spec(module, id, children \\ [], props \\ %{}),
    do: %{
      module: module,
      public_id: id,
      site: "example",
      key: id,
      props: props,
      slots: %{},
      children: children
    }

  def graph do
    %{
      "root" => spec(BlazeX.BH05.NestedShell, "root", ["group"], %{"kind" => "surface"}),
      "group" => spec(BlazeX.BH05.NestedShell, "group", ["a", "b"]),
      "a" => spec(BlazeX.BH05.NestedCounter, "a", ["label"]),
      "b" => spec(BlazeX.BH05.NestedCounter, "b", ["label"]),
      "label" => spec(BlazeX.BH05.NestedShell, "label", [], %{"kind" => "text"})
    }
  end

  def mount(graph \\ graph()), do: Nested.mount("nested", 1, "root", graph, boundary())
  def record(session, name), do: Enum.find(session.table.records, &(&1.public_id == name))

  def increment(session, name) do
    {:ok, event} =
      Event.new(
        :increment,
        session.table.root,
        record(session, name).identity,
        %{},
        session.table.sequence + 1
      )

    Nested.event(session, session.table.revision, event)
  end

  def reconcile(session, graph),
    do:
      Nested.reconcile(
        session,
        session.table.revision,
        session.table.root.generation,
        "root",
        graph
      )

  def script do
    {:ok, first} = mount()
    {:ok, second} = increment(first, "a")
    reordered = put_in(graph(), ["group", :children], ["b", "a"])
    {:ok, third} = reconcile(second, reordered)

    removed =
      reordered
      |> Map.delete("b")
      |> put_in(["group", :children], ["a", "c"])
      |> Map.put("c", spec(BlazeX.BH05.NestedCounter, "c", ["label"], %{"seed" => 7}))

    {:ok, fourth} = reconcile(third, removed)
    [first, second, third, fourth]
  end

  # Expected semantics authored independently of the nested evaluator.
  def oracle(order, states) do
    {:ok, root} = Identity.new("nested")
    {:ok, group_id} = Identity.child(root, {"group", "example", :child, "group"})

    entries =
      Enum.map(order, fn id ->
        {:ok, identity} = Identity.child(group_id, {id, "example", :child, id})
        {:ok, label_id} = Identity.child(identity, {"label", "example", :child, "label"})
        {:ok, label} = Node.text(label_id, "Count")
        {:ok, node} = Node.container(:action, identity, [label])
        {:ok, binding} = Binding.new(:increment, root, identity)

        {:ok, a11y} =
          Accessibility.new(identity, :button, name: Integer.to_string(Map.fetch!(states, id)))

        {node, binding, a11y}
      end)

    {:ok, group} = Node.container(:group, group_id, Enum.map(entries, &elem(&1, 0)))
    {:ok, surface} = Node.container(:surface, root, [group])
    {:ok, document} = Document.new(surface, Enum.map(entries, &elem(&1, 1)))
    {:ok, output} = IntentSet.new(document, accessibility: Enum.map(entries, &elem(&1, 2)))
    output
  end
end
