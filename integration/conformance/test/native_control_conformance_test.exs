defmodule BlazeX.NativeControlConformanceTest do
  use ExUnit.Case, async: true

  alias BlazeX.NativeSpike
  alias BlazeX.NativeSpike.{Batch, Fixture, Wire}
  alias BlazeX.Renderer.{DOM, Headless, Session}
  alias BlazeX.Renderer.DOM.Projection
  alias BlazeX.Renderer.Headless.Snapshot
  alias BlazeX.UITree.Node

  test "headless, DOM, and native batches preserve the representative semantic surface" do
    intent = Fixture.intent_set!()
    {:ok, semantic_nodes} = Node.preorder(intent.document.root)
    {:ok, headless} = Session.mount(Headless, intent)
    {:ok, dom} = Session.mount(DOM, intent)
    {:ok, native} = Session.mount(NativeSpike, intent)
    %Snapshot{} = snapshot = headless.artifact.value
    %DOM.Batch{root: dom_root} = dom.artifact.value
    %Batch{root: native_root} = native.artifact.value
    dom_nodes = flatten(dom_root)
    native_nodes = flatten(native_root)
    semantic_kinds = Enum.map(semantic_nodes, & &1.kind)

    assert headless_kinds(snapshot.tree) == semantic_kinds
    assert Enum.map(dom_nodes, &kind/1) == semantic_kinds
    assert Enum.map(native_nodes, &kind/1) == semantic_kinds

    assert Enum.map(dom_nodes, & &1.id) ==
             Enum.map(semantic_nodes, &BlazeX.Renderer.DOM.Portable.id(&1.identity))

    assert Enum.map(native_nodes, & &1.id) ==
             Enum.map(semantic_nodes, &BlazeX.NativeSpike.Portable.id(&1.identity))

    expected_events = intent.document.bindings |> Enum.map(& &1.event) |> Enum.sort()
    assert all_dom_events(dom_nodes) == Enum.map(expected_events, &Atom.to_string/1)
    assert all_native_events(native_nodes) == expected_events
    assert length(snapshot.bindings) == length(expected_events)
    assert length(snapshot.focus) == count_present(native_nodes, :focus)
    assert length(snapshot.selections) == count_present(native_nodes, :selection)
  end

  test "relationships and controlled state stay semantic across DOM and native projections" do
    intent = Fixture.intent_set!()
    {:ok, semantic_nodes} = Node.preorder(intent.document.root)
    field = Enum.find(semantic_nodes, &(&1.kind == :field))
    validation = List.last(semantic_nodes)
    {:ok, dom} = Session.mount(DOM, intent)
    {:ok, native} = Session.mount(NativeSpike, intent)
    dom_field = dom.artifact.value.root |> flatten() |> Enum.find(&(kind(&1) == :field))
    native_field = native.artifact.value.root |> flatten() |> Enum.find(&(&1.kind == :field))

    assert dom_field.id == BlazeX.Renderer.DOM.Portable.id(field.identity)

    assert dom_field.attributes["aria-describedby"] ==
             BlazeX.Renderer.DOM.Portable.id(validation.identity)

    assert dom_field.attributes["aria-errormessage"] ==
             BlazeX.Renderer.DOM.Portable.id(validation.identity)

    assert native_field.id == BlazeX.NativeSpike.Portable.id(field.identity)

    assert native_field.attributes.accessibility.relationships.described_by == [
             BlazeX.NativeSpike.Portable.id(validation.identity)
           ]

    assert native_field.attributes.accessibility.relationships.error_message == [
             BlazeX.NativeSpike.Portable.id(validation.identity)
           ]

    assert native_field.selection == %{
             kind: :text_range,
             value: %{anchor: 0, focus: 3, direction: :forward}
           }

    assert native_field.focus.auto_focus
  end

  test "all three renderer sessions agree on lifecycle while native batches remain deterministic" do
    first = Fixture.intent_set!(1)
    replacement = Fixture.intent_set!(2)

    sessions =
      for backend <- [Headless, DOM, NativeSpike], into: %{} do
        {:ok, mounted} = Session.mount(backend, first)
        {:ok, updated} = Session.update(mounted, first)
        {:ok, replaced} = Session.replace(updated, replacement)
        {:ok, disposed} = Session.dispose(replaced)
        {:ok, disposed_again} = Session.dispose(disposed)
        assert disposed == disposed_again
        assert {mounted.generation, mounted.revision} == {1, 0}
        assert {updated.generation, updated.revision} == {1, 1}
        assert {replaced.generation, replaced.revision} == {2, 0}
        assert disposed.status == :disposed
        {backend, %{mount: mounted, update: updated, replace: replaced, dispose: disposed}}
      end

    native = sessions[NativeSpike]
    assert native.mount.artifact.value.transition == :mount
    assert native.update.artifact.value.transition == :update
    assert native.replace.artifact.value.transition == :replace
    assert native.dispose.artifact.value.transition == :dispose
    assert native.dispose.artifact.value.root == nil

    {:ok, repeat} = Session.mount(NativeSpike, first)
    assert repeat.artifact.value == native.mount.artifact.value
    assert Wire.encode(repeat.artifact.value) == Wire.encode(native.mount.artifact.value)
  end

  defp flatten(%Projection{} = node), do: [node | Enum.flat_map(node.children, &flatten/1)]

  defp flatten(%BlazeX.NativeSpike.Node{} = node),
    do: [node | Enum.flat_map(node.children, &flatten/1)]

  defp kind(%Projection{} = node),
    do: String.to_existing_atom(node.attributes["data-bx-kind"])

  defp kind(%BlazeX.NativeSpike.Node{} = node), do: node.kind

  defp headless_kinds({:node, _version, kind, _identity, _key, _content, children}),
    do: [kind | Enum.flat_map(children, &headless_kinds/1)]

  defp all_dom_events(nodes),
    do: nodes |> Enum.flat_map(& &1.listeners) |> Enum.map(& &1.semantic) |> Enum.sort()

  defp all_native_events(nodes),
    do: nodes |> Enum.flat_map(& &1.listeners) |> Enum.map(& &1.semantic) |> Enum.sort()

  defp count_present(nodes, key), do: Enum.count(nodes, &(Map.fetch!(&1, key) != nil))
end
