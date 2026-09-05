defmodule BlazeX.CrossRendererConformanceTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.Session
  alias BlazeX.Renderer.DOM
  alias BlazeX.Renderer.DOM.{Batch, Projection}
  alias BlazeX.Renderer.Headless
  alias BlazeX.Renderer.Headless.Snapshot

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

  test "headless and DOM backends observe the same semantic interaction set" do
    output = interaction!(:cross_renderer, 1)
    {:ok, headless} = Session.mount(Headless, output)
    {:ok, dom} = Session.mount(DOM, output)
    %Snapshot{} = headless_snapshot = headless.artifact.value
    %Batch{root: dom_root} = dom.artifact.value

    assert semantic_kinds(headless_snapshot.tree) == dom_kinds(dom_root)
    assert length(headless_snapshot.bindings) == listener_count(dom_root)
    assert length(headless_snapshot.focus) == focus_count(dom_root)
    assert length(headless_snapshot.selections) == selection_count(dom_root)
    assert headless.owner == dom.owner
    assert {headless.generation, headless.revision} == {dom.generation, dom.revision}
  end

  test "both backends accept the same update, replacement, and disposal sequence" do
    first = interaction!(:lifecycle_parity, 1)
    replacement = interaction!(:lifecycle_parity, 2)
    {:ok, headless} = Session.mount(Headless, first)
    {:ok, dom} = Session.mount(DOM, first)
    {:ok, headless} = Session.update(headless, first)
    {:ok, dom} = Session.update(dom, first)
    assert {headless.generation, headless.revision} == {dom.generation, dom.revision}
    {:ok, headless} = Session.replace(headless, replacement)
    {:ok, dom} = Session.replace(dom, replacement)
    assert {headless.generation, headless.revision} == {dom.generation, dom.revision}
    {:ok, headless} = Session.dispose(headless)
    {:ok, dom} = Session.dispose(dom)
    assert headless.status == dom.status
    assert dom.artifact.value.root == nil

    assert Enum.map(headless.backend_state.trace.entries, & &1.transition) == [
             :mount,
             :update,
             :replace,
             :dispose
           ]
  end

  test "DOM lowering is deterministic for the same accepted semantic output" do
    output = interaction!({:deterministic, 1}, 1)
    {:ok, left} = Session.mount(DOM, output)
    {:ok, right} = Session.mount(DOM, output)
    assert Batch.to_wire(left.artifact.value) == Batch.to_wire(right.artifact.value)
  end

  defp interaction!(root_key, generation) do
    {:ok, root_id} = Identity.new(root_key, generation)
    {:ok, field_id} = Identity.child(root_id, :field)
    {:ok, action_id} = Identity.child(root_id, :action)
    {:ok, choice_id} = Identity.child(root_id, :choice)
    {:ok, field} = Node.new(:field, field_id, key: :field)
    {:ok, action} = Node.new(:action, action_id, key: :action)
    {:ok, choice} = Node.new(:selection, choice_id, key: :choice)
    {:ok, root} = Node.container(:surface, root_id, [field, action, choice])
    {:ok, change} = Binding.new(:change, root_id, field_id)
    {:ok, activate} = Binding.new(:activate, root_id, action_id)
    {:ok, select} = Binding.new(:select, root_id, choice_id)
    {:ok, document} = Document.new(root, [select, activate, change])
    {:ok, layout} = Layout.new(root_id, :stack, gap: {:units, 8})
    {:ok, surface_a11y} = Accessibility.new(root_id, :dialog, name: "Example")
    {:ok, field_a11y} = Accessibility.new(field_id, :text_field, name: "Name")
    {:ok, action_a11y} = Accessibility.new(action_id, :button, name: "Apply")
    {:ok, choice_a11y} = Accessibility.new(choice_id, :list_item, states: %{selected: true})
    {:ok, focus} = Focus.new(field_id, :target, order: 0, auto_focus: true)

    {:ok, range} =
      Selection.new(field_id, :text_range, %{anchor: 0, focus: 0, direction: :forward})

    {:ok, selected} = Selection.new(choice_id, :single, :dark)

    {:ok, intent} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [choice_a11y, action_a11y, field_a11y, surface_a11y],
        focus: [focus],
        selections: [selected, range]
      )

    intent
  end

  defp semantic_kinds({:node, _version, kind, _identity, _key, _content, children}),
    do: [kind | Enum.flat_map(children, &semantic_kinds/1)]

  defp dom_kinds(%Projection{} = node),
    do: [
      String.to_existing_atom(node.attributes["data-bx-kind"])
      | Enum.flat_map(node.children, &dom_kinds/1)
    ]

  defp listener_count(%Projection{} = node),
    do: length(node.listeners) + Enum.sum(Enum.map(node.children, &listener_count/1))

  defp focus_count(%Projection{} = node),
    do: present(node.focus) + Enum.sum(Enum.map(node.children, &focus_count/1))

  defp selection_count(%Projection{} = node),
    do: present(node.selection) + Enum.sum(Enum.map(node.children, &selection_count/1))

  defp present(nil), do: 0
  defp present(_value), do: 1
end
