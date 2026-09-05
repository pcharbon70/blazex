defmodule BlazeX.PresentationIntentTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.{Event, Identity}

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

  defmodule ControlledField do
    @behaviour BlazeX.Core.Component

    alias BlazeX.Core.{Event, Identity}

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

    @impl true
    def mode, do: :stateful

    @impl true
    def init(props, _context), do: {:ok, props.value}

    @impl true
    def update(props, _state, _context), do: {:ok, props.value}

    @impl true
    def handle_event(%Event{name: :change, payload: %{value: value}}, _props, _state, _context),
      do: {:ok, value, []}

    @impl true
    def render(_props, :invalid, _context) do
      {:ok,
       %IntentSet{
         version: 2,
         document: nil,
         layouts: [],
         accessibility: [],
         focus: [],
         selections: []
       }}
    end

    def render(_props, value, context) do
      {:ok, label_id} = Identity.child(context.identity, :label)
      {:ok, field_id} = Identity.child(context.identity, :field)
      {:ok, label} = Node.text(label_id, "Name", key: :label)
      {:ok, field} = Node.container(:field, field_id, [], key: :field)
      {:ok, root} = Node.container(:group, context.identity, [label, field])
      {:ok, binding} = Binding.new(:change, context.identity, field_id)
      {:ok, document} = Document.new(root, [binding])
      {:ok, layout} = Layout.new(context.identity, :stack, gap: {:units, 8})
      {:ok, label_accessibility} = Accessibility.new(label_id, :text, name: "Name")

      {:ok, field_accessibility} =
        Accessibility.new(field_id, :text_field,
          name: "Name",
          states: %{required: true},
          relationships: %{labelled_by: [label_id]}
        )

      {:ok, focus} = Focus.new(field_id, :target, order: 0)

      {:ok, selection} =
        Selection.new(field_id, :text_range, %{
          anchor: 0,
          focus: byte_size(value),
          direction: :forward
        })

      IntentSet.new(document,
        layouts: [layout],
        accessibility: [label_accessibility, field_accessibility],
        focus: [focus],
        selections: [selection]
      )
    end
  end

  test "accessibility, focus, and selection vocabularies are exact" do
    assert Accessibility.roles() == [
             :generic,
             :text,
             :group,
             :button,
             :text_field,
             :checkbox,
             :list,
             :list_item,
             :dialog,
             :status
           ]

    assert Accessibility.state_keys() == [
             :disabled,
             :expanded,
             :selected,
             :checked,
             :invalid,
             :required,
             :readonly,
             :busy
           ]

    assert Accessibility.relationship_keys() == [
             :labelled_by,
             :described_by,
             :controls,
             :owns,
             :error_message
           ]

    assert Accessibility.live_values() == [:off, :polite, :assertive]
    assert Focus.behaviors() == [:none, :target, :scope]
    assert Focus.restore_values() == [:none, :previous]
    assert Selection.kinds() == [:none, :single, :multiple, :text_range]
    assert Selection.directions() == [:forward, :backward]
  end

  test "intent set validates in-tree relationships, focus, and controlled selection" do
    %{intent_set: intent_set} = valid_intent_set()
    assert IntentSet.validate(intent_set) == :ok
    assert BlazeX.UITree.validate(intent_set) == :ok
  end

  test "intent set rejects missing relationships and duplicate annotation owners" do
    %{document: document, field: field, intent_set: intent_set} = valid_intent_set()
    {:ok, missing} = Identity.child(document.root.identity, :missing)

    {:ok, bad_accessibility} =
      Accessibility.new(field, :text_field, relationships: %{labelled_by: [missing]})

    assert {:error, :accessibility_relationship_target_missing} =
             IntentSet.new(document, accessibility: [bad_accessibility])

    [layout] = intent_set.layouts

    assert {:error, :duplicate_annotation_owner} =
             IntentSet.new(document, layouts: [layout, layout])
  end

  test "intent set rejects duplicate focus order and incompatible selections" do
    %{document: document, label: label, field: field} = valid_intent_set()
    {:ok, focus_field} = Focus.new(field, :target, order: 0)
    {:ok, focus_label} = Focus.new(label, :target, order: 0)

    assert {:error, :duplicate_focus_order} =
             IntentSet.new(document, focus: [focus_field, focus_label])

    {:ok, selection} =
      Selection.new(label, :text_range, %{anchor: 0, focus: 1, direction: :forward})

    assert {:error, :selection_kind_incompatible} =
             IntentSet.new(document, selections: [selection])
  end

  test "intent set rejects stale-generation annotation owners" do
    %{document: document, field: field} = valid_intent_set()
    {:ok, stale_field} = Identity.replace(field)
    {:ok, stale_focus} = Focus.new(stale_field, :target, order: 0)
    assert {:error, :annotation_owner_missing} = IntentSet.new(document, focus: [stale_focus])
  end

  test "component intent output remains atomic across update, event, and replacement" do
    {:ok, owner} = Identity.new(:controlled_field)
    assert {:ok, mounted} = BlazeX.UITree.mount_component(ControlledField, owner, %{value: "a"})
    assert %IntentSet{} = mounted.output

    assert {:ok, updated} = BlazeX.UITree.update_component(mounted, %{value: "abcd"})
    assert hd(updated.output.selections).value.focus == 4
    field = updated.output.document.bindings |> hd() |> Map.fetch!(:source)
    {:ok, event} = Event.new(:change, owner, field, %{value: "xy"}, 1)
    assert {:ok, dispatched, []} = BlazeX.UITree.dispatch_component(updated, event)
    assert hd(dispatched.output.selections).value.focus == 2

    assert {:ok, replaced} = BlazeX.UITree.replace_component(dispatched, %{value: "z"})
    assert replaced.identity.generation == 2
    assert hd(replaced.output.focus).owner.generation == 2

    assert {:error, %{code: :invalid_semantic_output}} =
             BlazeX.UITree.update_component(dispatched, %{value: :invalid})

    assert dispatched.state == "xy"
    assert IntentSet.validate(dispatched.output) == :ok
  end

  defp valid_intent_set do
    {:ok, owner} = Identity.new(:intent_set)
    {:ok, label} = Identity.child(owner, :label)
    {:ok, field} = Identity.child(owner, :field)
    {:ok, label_node} = Node.text(label, "Label", key: :label)
    {:ok, field_node} = Node.container(:field, field, [], key: :field)
    {:ok, root} = Node.container(:group, owner, [label_node, field_node])
    {:ok, document} = Document.new(root)
    {:ok, layout} = Layout.new(owner, :stack, gap: {:units, 4})
    {:ok, label_accessibility} = Accessibility.new(label, :text, name: "Label")

    {:ok, field_accessibility} =
      Accessibility.new(field, :text_field,
        relationships: %{labelled_by: [label]},
        states: %{required: true}
      )

    {:ok, focus} = Focus.new(field, :target, order: 0, auto_focus: true)

    {:ok, selection} =
      Selection.new(field, :text_range, %{anchor: 0, focus: 0, direction: :forward})

    {:ok, intent_set} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [label_accessibility, field_accessibility],
        focus: [focus],
        selections: [selection]
      )

    %{document: document, label: label, field: field, intent_set: intent_set}
  end
end
