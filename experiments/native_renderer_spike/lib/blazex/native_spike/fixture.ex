defmodule BlazeX.NativeSpike.Fixture do
  @moduledoc "The frozen representative semantic slice for direct-platform execution."

  alias BlazeX.Core.Identity
  alias BlazeX.Effects.Effect

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

  def intent_set!(generation \\ 1) do
    {:ok, root_id} = Identity.new(:native_portability, generation)
    ids = identities(root_id)
    {:ok, title} = Node.text(ids.title, "Native portability", key: :title)
    {:ok, action} = Node.new(:action, ids.action, key: :action)
    {:ok, field} = Node.new(:field, ids.field, key: :field)
    {:ok, check} = Node.new(:selection, ids.check, key: :check)
    {:ok, first} = Node.new(:selection, ids.first, key: :first)
    {:ok, second} = Node.new(:selection, ids.second, key: :second)

    {:ok, collection} =
      Node.container(:collection, ids.collection, [first, second], key: :collection)

    {:ok, validation} = Node.text(ids.validation, "Name is required", key: :validation)

    {:ok, group} =
      Node.container(:group, ids.group, [title, action, field, check, collection, validation],
        key: :group
      )

    {:ok, root} = Node.container(:surface, root_id, [group])
    {:ok, activate} = Binding.new(:activate, root_id, ids.action)
    {:ok, change} = Binding.new(:change, root_id, ids.field)
    {:ok, select_check} = Binding.new(:select, root_id, ids.check)
    {:ok, select_list} = Binding.new(:select, root_id, ids.collection)
    {:ok, document} = Document.new(root, [activate, change, select_check, select_list])
    {:ok, layout} = Layout.new(ids.group, :stack, direction: :column, align: :stretch)
    {:ok, root_a11y} = Accessibility.new(root_id, :dialog, name: "Native portability")
    {:ok, group_a11y} = Accessibility.new(ids.group, :group)
    {:ok, title_a11y} = Accessibility.new(ids.title, :text)
    {:ok, action_a11y} = Accessibility.new(ids.action, :button, name: "Apply")

    {:ok, field_a11y} =
      Accessibility.new(ids.field, :text_field,
        name: "Name",
        states: %{required: true, invalid: true},
        relationships: %{described_by: [ids.validation], error_message: [ids.validation]}
      )

    {:ok, check_a11y} =
      Accessibility.new(ids.check, :checkbox, name: "Enabled", states: %{checked: true})

    {:ok, list_a11y} = Accessibility.new(ids.collection, :list, name: "Choices")
    {:ok, first_a11y} = Accessibility.new(ids.first, :list_item, name: "First")

    {:ok, second_a11y} =
      Accessibility.new(ids.second, :list_item, name: "Second", states: %{selected: true})

    {:ok, validation_a11y} = Accessibility.new(ids.validation, :status, live: :polite)
    {:ok, focus} = Focus.new(ids.field, :target, order: 0, auto_focus: true)

    {:ok, field_selection} =
      Selection.new(ids.field, :text_range, %{anchor: 0, focus: 3, direction: :forward})

    {:ok, checked} = Selection.new(ids.check, :single, true)
    {:ok, selected} = Selection.new(ids.collection, :single, :second)

    {:ok, intent} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [
          root_a11y,
          group_a11y,
          title_a11y,
          action_a11y,
          field_a11y,
          check_a11y,
          list_a11y,
          first_a11y,
          second_a11y,
          validation_a11y
        ],
        focus: [focus],
        selections: [field_selection, checked, selected]
      )

    intent
  end

  def file_choice_effect!(generation \\ 1) do
    {:ok, owner} = Identity.new(:native_portability, generation)

    {:ok, effect} =
      Effect.new(:choose_source, owner, :"ui.files.choose", :choose, %{
        accept: ["text/plain"],
        multiple: false
      })

    effect
  end

  defp identities(root) do
    {:ok, group} = Identity.child(root, :group)

    [:title, :action, :field, :check, :collection, :validation]
    |> Map.new(fn key ->
      {:ok, id} = Identity.child(group, key)
      {key, id}
    end)
    |> Map.put(:group, group)
    |> add_list_item(:collection, :first)
    |> add_list_item(:collection, :second)
  end

  defp add_list_item(ids, parent_key, key) do
    {:ok, id} = Identity.child(ids[parent_key], key)
    Map.put(ids, key, id)
  end
end
