defmodule BlazeX.BH04.ReconciliationCases do
  @moduledoc false
  alias BlazeX.Core.Identity

  alias BlazeX.UITree.{
    Accessibility,
    Binding,
    Document,
    Focus,
    IntentSet,
    Layout,
    Node,
    Selection
  }

  alias BlazeX.Renderer.DOM.{Batch, Projection, ReconciledSession, Retained}
  alias BlazeX.Renderer.DOM.ProtocolV2.IntentData
  alias BlazeX.Renderer.Session

  def tree(spec, generation \\ 1, kind \\ :group) do
    {:ok, id} = Identity.new({:phase3, -7}, generation)
    {:ok, root} = Node.container(kind, id, children(id, spec))
    root
  end

  defp children(parent, spec) do
    Enum.map(spec, fn {key, value} ->
      {:ok, id} = Identity.child(parent, key)

      {:ok, node} =
        if is_list(value),
          do: Node.container(:group, id, children(id, value), key: key),
          else: Node.text(id, value, key: key)

      node
    end)
  end

  def rich(mode \\ 1, generation \\ 1) do
    {:ok, owner} = Identity.new({:phase3, -7}, generation)
    {:ok, field_id} = Identity.child(owner, :field)
    {:ok, action_id} = Identity.child(owner, :action)
    {:ok, label_id} = Identity.child(owner, :label)
    {:ok, field} = Node.new(:field, field_id, key: :field)
    {:ok, action} = Node.new(:action, action_id, key: :action)
    {:ok, label} = Node.text(label_id, "Name #{mode} 🌍", key: :label)

    {:ok, root} =
      Node.container(
        :surface,
        owner,
        if(mode == 1, do: [label, field, action], else: [action, label, field])
      )

    {:ok, change} = Binding.new(:change, owner, field_id)
    {:ok, activate} = Binding.new(:activate, owner, action_id)
    {:ok, document} = Document.new(root, if(mode == 1, do: [change, activate], else: [change]))
    {:ok, layout} = Layout.new(owner, :stack, gap: {:units, mode * 8})

    {:ok, root_a11y} =
      Accessibility.new(owner, :dialog,
        name: "Example",
        relationships: %{labelled_by: [label_id]}
      )

    {:ok, field_a11y} =
      Accessibility.new(field_id, :text_field,
        name: "Name",
        relationships: %{described_by: [label_id]}
      )

    {:ok, action_a11y} =
      Accessibility.new(action_id, :button, name: "Apply", relationships: %{controls: [field_id]})

    {:ok, focus} = Focus.new(field_id, :target, order: mode, auto_focus: mode == 1)

    {:ok, selection} =
      Selection.new(field_id, :text_range, %{anchor: 0, focus: mode, direction: :forward})

    {:ok, intent} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [root_a11y, field_a11y, action_a11y],
        focus: [focus],
        selections: [selection]
      )

    intent
  end

  def scenarios do
    basic = tree(a: "A", b: "B", c: "C")
    nested = tree(left: [a: "A", b: "B"], right: [c: "C"])

    [
      {"initial", nil, rich(), :mount},
      {"noop", rich(), rich(), :update},
      {"leaf", basic, tree(a: "new", b: "B", c: "C"), :update},
      {"keyed-reorder", basic, tree(c: "C", a: "A", b: "B"), :update},
      {"nested-insert-remove", nested, tree(left: [b: "B", d: [e: "E"]], right: []), :update},
      {"cross-parent-new-identity", nested, tree(left: [b: "B"], right: [a: "A", c: "C"]),
       :update},
      {"listeners-layout-relationships-focus-selection", rich(), rich(2), :update},
      {"root-materialization-replace", basic, tree([a: "A", b: "B", c: "C"], 1, :surface),
       :update},
      {"generation-replace", rich(), rich(2, 2), :replace},
      {"dispose", rich(), nil, :dispose}
    ] ++
      Enum.map(1..40, fn seed ->
        old = tree(Enum.map(1..8, &{&1, "#{&1}"}))

        keys =
          Enum.reject(1..8, &(rem(&1 + seed, 4) == 0)) |> Enum.sort_by(&rem(&1 * 7 + seed, 13))

        {"generated-#{seed}", old,
         tree(Enum.map(keys ++ [100 + seed], &{&1, "#{&1 + rem(seed, 2)}"})), :update}
      end)
  end

  def ack(facade, outcome \\ nil) do
    tx = ReconciledSession.transaction(facade)
    outcome = outcome || if(tx["kind"] == "dispose", do: "disposed", else: "committed")

    tx
    |> Map.take(
      ~w(protocol schema owner generation root base_revision target_revision transaction_id digest)
    )
    |> Map.merge(%{
      "record" => "ack",
      "state" => outcome,
      "diagnostic" => if(outcome in ~w(rejected rolled-back), do: "apply", else: nil)
    })
  end

  def execute({name, old, next, stage}) do
    facade =
      if old do
        {:ok, mounted} = ReconciledSession.mount(old)
        {:ok, committed} = ReconciledSession.acknowledge(mounted, ack(mounted))
        committed
      else
        nil
      end

    {:ok, proposed} =
      case stage do
        :mount -> ReconciledSession.mount(next)
        :dispose -> ReconciledSession.dispose(facade)
        _ -> apply(ReconciledSession, stage, [facade, next])
      end

    tx = ReconciledSession.transaction(proposed)
    context = proposed.state.pending.context
    accepted = if facade, do: Retained.wire(facade.state.accepted), else: nil
    {:ok, committed} = ReconciledSession.acknowledge(proposed, ack(proposed))

    if next do
      {:ok, full} = Session.mount(BlazeX.Renderer.DOM, next)
      %Batch{root: projection} = full.artifact.value
      true = projection_wire(committed.state.accepted) == Projection.to_wire(projection)
    end

    %{
      "name" => name,
      "context" => context,
      "transaction" => tx,
      "before" => accepted,
      "after" =>
        if(committed.state.accepted, do: Retained.wire(committed.state.accepted), else: nil),
      "ack" => ack(proposed),
      "decision" => %{
        "replacements" => proposed.state.pending.decision.replacements,
        "operations" => length(tx["operations"])
      }
    }
  end

  def projection_wire(state), do: projection_node(state, state.root)

  defp projection_node(state, id) do
    node = state.nodes[id]

    %{
      "version" => 1,
      "id" => id,
      "tag" => node["tag"],
      "text" => node["text"],
      "attributes" => Retained.values(node["attributes"]),
      "focus" => IntentData.unpack(node["focus"]),
      "selection" => IntentData.unpack(node["selection"]),
      "listeners" => IntentData.unpack(node["listeners"]) || [],
      "children" => Enum.map(node["children"], &projection_node(state, &1))
    }
  end
end
