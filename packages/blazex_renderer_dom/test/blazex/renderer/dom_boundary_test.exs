defmodule BlazeX.Renderer.DOMBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.Session
  alias BlazeX.Renderer.DOM
  alias BlazeX.Renderer.DOM.{Batch, Listener, Portable}

  alias BlazeX.UITree.{
    Accessibility,
    Binding,
    Document,
    Focus,
    IntentSet,
    Layout,
    Node,
    Selection,
    TokenRef
  }

  test "declares the complete frozen renderer capability set" do
    assert DOM.capabilities() == BlazeX.Renderer.Capabilities.full()
  end

  test "lowers all semantic node kinds and preserves child order" do
    intent = intent_set!(:all_kinds, 1)
    {:ok, session} = Session.mount(DOM, intent)
    %Batch{root: root} = session.artifact.value

    assert root.tag == "section"
    assert root.attributes["role"] == "dialog"

    assert Enum.map(root.children, & &1.attributes["data-bx-kind"]) == [
             "text",
             "group",
             "action",
             "field",
             "selection",
             "collection"
           ]

    assert Enum.map(root.children, & &1.tag) == ["span", "div", "button", "input", "li", "ul"]
  end

  test "lowers bindings, accessibility, layout tokens, focus, and selection" do
    intent = intent_set!(:complete_intent, 1)
    {:ok, session} = Session.mount(DOM, intent)
    %Batch{root: root} = session.artifact.value
    [text, group, action, field, selection, _collection] = root.children

    assert root.attributes["aria-labelledby"] == text.id
    assert root.attributes["aria-label"] == "Preferences"
    assert root.attributes["aria-live"] == "polite"
    assert group.attributes["data-bx-layout-mode"] == "stack"
    assert group.attributes["data-bx-layout-gap"] =~ "token:space:"
    assert [%{semantic: "activate", native: "click"}] = action.listeners
    assert field.attributes["aria-required"] == "true"
    assert field.focus.auto_focus
    assert field.selection.kind == "text_range"
    assert selection.selection.kind == "single"
  end

  test "produces deterministic IDs, wire maps, and SHA-256 digests" do
    intent = intent_set!({:portable, [:root, 7]}, 1)
    {:ok, first} = Session.mount(DOM, intent)
    {:ok, second} = Session.mount(DOM, intent)

    assert first.artifact == second.artifact
    batch = first.artifact.value
    assert batch.root.id == Portable.id(intent.document.root.identity)
    assert batch.root.id =~ ~r/^bx-[0-9a-f]{24}$/
    assert batch.digest =~ ~r/^[0-9a-f]{64}$/
    assert plain_wire?(Batch.to_wire(batch))
  end

  test "maps every current semantic event to its frozen native trigger" do
    {:ok, owner} = Identity.new(:events)
    {:ok, source} = Identity.child(owner, :source)

    mappings =
      Map.new(BlazeX.Core.Event.names(), fn event ->
        {:ok, binding} = Binding.new(event, owner, source)
        listener = Listener.new(binding)
        {listener.semantic, listener.native}
      end)

    assert mappings == %{
             "activate" => "click",
             "change" => "input",
             "decrement" => "click",
             "dismiss" => "click",
             "expand" => "click",
             "increment" => "click",
             "move" => "pointermove",
             "reorder" => "drop",
             "request_close" => "click",
             "request_open" => "click",
             "request_page" => "click",
             "select" => "change",
             "submit" => "submit"
           }
  end

  test "tracks mount, update, replacement, and idempotent disposal" do
    first = intent_set!(:lifecycle, 1)
    replacement = intent_set!(:lifecycle, 2)
    {:ok, mounted} = Session.mount(DOM, first)
    {:ok, updated} = Session.update(mounted, first)
    {:ok, replaced} = Session.replace(updated, replacement)
    {:ok, disposed} = Session.dispose(replaced)
    {:ok, disposed_again} = Session.dispose(disposed)

    assert mounted.artifact.value.transition == "mount"

    assert {updated.generation, updated.revision, updated.artifact.value.transition} ==
             {1, 1, "update"}

    assert {replaced.generation, replaced.revision, replaced.artifact.value.transition} ==
             {2, 0, "replace"}

    assert disposed.artifact.value.transition == "dispose"
    assert disposed.artifact.value.root == nil
    assert disposed == disposed_again
  end

  test "invalid output is rejected before a DOM projection is accepted" do
    intent = intent_set!(:invalid, 1)

    invalid = %{
      intent
      | document: %{intent.document | root: %{intent.document.root | kind: :iframe}}
    }

    assert {:error, %BlazeX.Renderer.Diagnostic{code: :invalid_semantic_output}} =
             Session.mount(DOM, invalid)
  end

  test "the standalone Elixir source has no server-framework coupling" do
    root = Path.expand("../../../lib", __DIR__)

    source =
      root
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.map_join("\n", &File.read!/1)

    for forbidden <- ["Phoenix", "Plug", "LiveView", "LocalLiveView"] do
      refute source =~ forbidden
    end
  end

  defp intent_set!(root_key, generation) do
    {:ok, root_id} = Identity.new(root_key, generation)
    keys = [:text, :group, :action, :field, :selection, :collection]

    identities =
      Map.new(keys, fn key ->
        {:ok, identity} = Identity.child(root_id, key)
        {key, identity}
      end)

    {:ok, text} = Node.text(identities.text, "Preferences", key: :text)
    {:ok, group} = Node.new(:group, identities.group, key: :group)
    {:ok, action} = Node.new(:action, identities.action, key: :action)
    {:ok, field} = Node.new(:field, identities.field, key: :field)
    {:ok, selection_node} = Node.new(:selection, identities.selection, key: :selection)
    {:ok, collection} = Node.new(:collection, identities.collection, key: :collection)

    {:ok, root} =
      Node.container(:surface, root_id, [text, group, action, field, selection_node, collection])

    {:ok, action_binding} = Binding.new(:activate, root_id, identities.action)
    {:ok, change_binding} = Binding.new(:change, root_id, identities.field)
    {:ok, document} = Document.new(root, [change_binding, action_binding])
    {:ok, space} = TokenRef.new(:space, :control_gap)
    {:ok, layout} = Layout.new(identities.group, :stack, gap: {:token, space})

    {:ok, root_a11y} =
      Accessibility.new(root_id, :dialog,
        name: "Preferences",
        relationships: %{labelled_by: [identities.text]},
        live: :polite
      )

    {:ok, text_a11y} = Accessibility.new(identities.text, :text)
    {:ok, group_a11y} = Accessibility.new(identities.group, :group)
    {:ok, action_a11y} = Accessibility.new(identities.action, :button, name: "Apply")

    {:ok, field_a11y} =
      Accessibility.new(identities.field, :text_field, states: %{required: true})

    {:ok, selection_a11y} = Accessibility.new(identities.selection, :list_item)
    {:ok, collection_a11y} = Accessibility.new(identities.collection, :list)
    {:ok, focus} = Focus.new(identities.field, :target, order: 0, auto_focus: true)

    {:ok, text_selection} =
      Selection.new(identities.field, :text_range, %{anchor: 0, focus: 0, direction: :forward})

    {:ok, choice_selection} = Selection.new(identities.selection, :single, :dark)

    {:ok, intent} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [
          collection_a11y,
          selection_a11y,
          field_a11y,
          action_a11y,
          group_a11y,
          text_a11y,
          root_a11y
        ],
        focus: [focus],
        selections: [choice_selection, text_selection]
      )

    intent
  end

  defp plain_wire?(value) when is_map(value) and not is_struct(value),
    do: Enum.all?(value, fn {key, child} -> is_binary(key) and plain_wire?(child) end)

  defp plain_wire?(value) when is_list(value), do: Enum.all?(value, &plain_wire?/1)

  defp plain_wire?(value),
    do: is_nil(value) or is_binary(value) or is_number(value) or is_boolean(value)
end
