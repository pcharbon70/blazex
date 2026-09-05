defmodule BlazeX.NativeSpikeBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.NativeSpike
  alias BlazeX.NativeSpike.{Batch, Wire}
  alias BlazeX.Renderer.Session

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

  test "declares the bounded native experiment capabilities" do
    capabilities = NativeSpike.capabilities()
    assert capabilities.node_kinds == Node.kinds()
    assert capabilities.layout_modes == [:none, :stack]

    assert capabilities.features == [
             :event_bindings,
             :logical_layout,
             :accessibility,
             :focus,
             :selection
           ]
  end

  test "lowers every semantic kind without platform objects" do
    intent = fixture!(:native_all_kinds, 1)
    {:ok, session} = Session.mount(NativeSpike, intent)
    %Batch{root: root} = session.artifact.value
    assert root.kind == :surface

    assert Enum.map(root.children, & &1.kind) == [
             :text,
             :group,
             :action,
             :field,
             :selection,
             :collection
           ]

    assert Enum.all?(flatten(root), &String.starts_with?(&1.id, "bn-"))
  end

  test "preserves stack, accessibility, binding, focus, selection, and relationship intent" do
    intent = fixture!(:native_intent, 1)
    {:ok, session} = Session.mount(NativeSpike, intent)
    [text, group, action, field, selection, _collection] = session.artifact.value.root.children
    assert group.attributes.layout.mode == :stack
    assert action.listeners |> Enum.map(& &1.semantic) == [:activate]

    assert field.focus == %{
             behavior: :target,
             order: 0,
             auto_focus: true,
             restore: :none,
             wrap: false
           }

    assert field.selection.kind == :text_range
    assert selection.selection.kind == :single

    assert session.artifact.value.root.attributes.accessibility.relationships.labelled_by == [
             text.id
           ]
  end

  test "produces deterministic identities, digests, and BXN1 wire" do
    intent = fixture!({:portable, 7}, 1)
    {:ok, first} = Session.mount(NativeSpike, intent)
    {:ok, second} = Session.mount(NativeSpike, intent)
    assert first.artifact == second.artifact
    assert first.artifact.value.digest =~ ~r/^[0-9a-f]{64}$/
    assert Wire.encode(first.artifact.value) == Wire.encode(second.artifact.value)
    assert {:ok, decoded} = first.artifact.value |> Wire.encode() |> Wire.decode()
    assert length(decoded.records) == 7
  end

  test "tracks renderer lifecycle and encodes rootless disposal" do
    first = fixture!(:lifecycle, 1)
    replacement = fixture!(:lifecycle, 2)
    {:ok, mounted} = Session.mount(NativeSpike, first)
    {:ok, updated} = Session.update(mounted, first)
    {:ok, replaced} = Session.replace(updated, replacement)
    {:ok, disposed} = Session.dispose(replaced)
    {:ok, disposed_again} = Session.dispose(disposed)
    assert {mounted.generation, mounted.revision} == {1, 0}
    assert {updated.generation, updated.revision} == {1, 1}
    assert {replaced.generation, replaced.revision} == {2, 0}
    assert disposed.artifact.value.root == nil
    assert Wire.encode(disposed.artifact.value) =~ "\tdispose\t"
    assert disposed == disposed_again
  end

  test "fails closed on unsupported layout and malformed wire" do
    intent = fixture!(:unsupported, 1)
    group = Enum.at(intent.document.root.children, 1)
    {:ok, grid} = Layout.new(group.identity, :grid)

    assert {:error, %BlazeX.Renderer.Diagnostic{code: :missing_renderer_capability}} =
             Session.mount(NativeSpike, %{intent | layouts: [grid]})

    assert {:error, :unknown_native_record} =
             Wire.decode("BXN1\t1\t0\tmount\t#{String.duplicate("a", 64)}\t6f6b\nEVIL\nEND\n")
  end

  test "file-choice stays an opaque effect intent outside platform projection" do
    {:ok, owner} = Identity.new(:file_effect)

    assert {:ok, effect} =
             BlazeX.Effects.Effect.new(
               :choose_source,
               owner,
               :"ui.files.choose",
               :choose,
               %{accept: ["text/plain"], multiple: false}
             )

    refute inspect(effect) =~ "Gtk"
    refute inspect(effect) =~ "HWND"
    refute inspect(effect) =~ "NSOpenPanel"
  end

  test "experiment source has no server, browser, or cross-platform toolkit imports" do
    source =
      Path.expand("../lib", __DIR__)
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.map_join("\n", &File.read!/1)

    for forbidden <- [
          "Phoenix",
          "Plug",
          "LiveView",
          "LocalLiveView",
          "HTMLElement",
          "JavaScript",
          "Qt",
          "wxWidgets"
        ] do
      refute source =~ forbidden
    end
  end

  defp fixture!(key, generation) do
    {:ok, root_id} = Identity.new(key, generation)
    keys = [:text, :group, :action, :field, :selection, :collection]

    ids =
      Map.new(keys, fn child ->
        {:ok, id} = Identity.child(root_id, child)
        {child, id}
      end)

    {:ok, text} = Node.text(ids.text, "Preferences", key: :text)
    {:ok, group} = Node.new(:group, ids.group, key: :group)
    {:ok, action} = Node.new(:action, ids.action, key: :action)
    {:ok, field} = Node.new(:field, ids.field, key: :field)
    {:ok, selection_node} = Node.new(:selection, ids.selection, key: :selection)
    {:ok, collection} = Node.new(:collection, ids.collection, key: :collection)

    {:ok, root} =
      Node.container(:surface, root_id, [text, group, action, field, selection_node, collection])

    {:ok, activate} = Binding.new(:activate, root_id, ids.action)
    {:ok, change} = Binding.new(:change, root_id, ids.field)
    {:ok, document} = Document.new(root, [change, activate])
    {:ok, layout} = Layout.new(ids.group, :stack)

    {:ok, root_a11y} =
      Accessibility.new(root_id, :dialog, relationships: %{labelled_by: [ids.text]})

    {:ok, text_a11y} = Accessibility.new(ids.text, :text)
    {:ok, group_a11y} = Accessibility.new(ids.group, :group)
    {:ok, action_a11y} = Accessibility.new(ids.action, :button, name: "Apply")
    {:ok, field_a11y} = Accessibility.new(ids.field, :text_field, states: %{required: true})
    {:ok, selection_a11y} = Accessibility.new(ids.selection, :checkbox)
    {:ok, collection_a11y} = Accessibility.new(ids.collection, :list)
    {:ok, focus} = Focus.new(ids.field, :target, order: 0, auto_focus: true)

    {:ok, text_selection} =
      Selection.new(ids.field, :text_range, %{anchor: 0, focus: 0, direction: :forward})

    {:ok, checked} = Selection.new(ids.selection, :single, true)

    {:ok, intent} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [
          root_a11y,
          text_a11y,
          group_a11y,
          action_a11y,
          field_a11y,
          selection_a11y,
          collection_a11y
        ],
        focus: [focus],
        selections: [text_selection, checked]
      )

    intent
  end

  defp flatten(node), do: [node | Enum.flat_map(node.children, &flatten/1)]
end
