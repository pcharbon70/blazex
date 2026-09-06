defmodule BlazeX.NativeSpike.Lowerer do
  @moduledoc false

  alias BlazeX.NativeSpike.{Node, Portable}
  alias BlazeX.UITree.{Accessibility, Document, Focus, IntentSet, Layout, Selection}
  alias BlazeX.UITree.Node, as: SemanticNode

  def lower(%SemanticNode{} = node), do: lower_parts(node, [], [], [], [], [])

  def lower(%Document{} = document),
    do: lower_parts(document.root, document.bindings, [], [], [], [])

  def lower(%IntentSet{} = intent) do
    lower_parts(
      intent.document.root,
      intent.document.bindings,
      intent.layouts,
      intent.accessibility,
      intent.focus,
      intent.selections
    )
  end

  def lower(_output), do: {:error, :invalid_semantic_output}

  defp lower_parts(root, bindings, layouts, accessibility, focus, selections) do
    annotations = %{
      bindings: Enum.group_by(bindings, & &1.source),
      layouts: Map.new(layouts, &{&1.owner, &1}),
      accessibility: Map.new(accessibility, &{&1.owner, &1}),
      focus: Map.new(focus, &{&1.owner, &1}),
      selections: Map.new(selections, &{&1.owner, &1})
    }

    {:ok, lower_node(root, annotations)}
  end

  defp lower_node(%BlazeX.UITree.Node{} = semantic, annotations) do
    accessibility = annotations.accessibility[semantic.identity]
    layout = annotations.layouts[semantic.identity]

    %Node{
      version: 1,
      id: Portable.id(semantic.identity),
      kind: semantic.kind,
      text: semantic.content,
      attributes: attributes(accessibility, layout),
      listeners:
        annotations.bindings
        |> Map.get(semantic.identity, [])
        |> Enum.map(&listener/1)
        |> Enum.sort_by(& &1.semantic),
      focus: focus(annotations.focus[semantic.identity]),
      selection: selection(annotations.selections[semantic.identity]),
      children: Enum.map(semantic.children, &lower_node(&1, annotations))
    }
  end

  defp attributes(accessibility, layout) do
    %{accessibility: accessibility(accessibility), layout: layout(layout)}
  end

  defp accessibility(nil), do: nil

  defp accessibility(%Accessibility{} = value) do
    %{
      role: value.role,
      name: value.name,
      description: value.description,
      states: value.states,
      relationships:
        Map.new(value.relationships, fn {key, identities} ->
          {key, Enum.map(identities, &Portable.id/1)}
        end),
      live: value.live
    }
  end

  defp layout(nil), do: nil

  defp layout(%Layout{} = value) do
    %{
      mode: value.mode,
      direction: value.direction,
      align: value.align,
      gap: value.gap,
      padding: value.padding,
      grow: value.grow,
      overflow: value.overflow
    }
  end

  defp listener(binding) do
    %{
      semantic: binding.event,
      owner: Portable.identity(binding.owner),
      source: Portable.identity(binding.source)
    }
  end

  defp focus(nil), do: nil

  defp focus(%Focus{} = value) do
    %{
      behavior: value.behavior,
      order: value.order,
      auto_focus: value.auto_focus,
      restore: value.restore,
      wrap: value.wrap
    }
  end

  defp selection(nil), do: nil

  defp selection(%Selection{} = value) do
    %{kind: value.kind, value: selection_value(value.kind, value.value)}
  end

  defp selection_value(:text_range, value), do: value
  defp selection_value(:none, nil), do: nil
  defp selection_value(:multiple, values), do: Enum.map(values, &Portable.encode/1)
  defp selection_value(:single, value), do: Portable.encode(value)
end
