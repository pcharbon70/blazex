defmodule BlazeX.Renderer.Headless.Normalizer do
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
    Selection,
    TokenRef
  }

  @spec normalize(Node.t() | Document.t() | IntentSet.t()) :: {:ok, map()} | {:error, atom()}
  def normalize(%Node{} = node), do: normalize_parts(node, [], [], [], [], [])

  def normalize(%Document{} = document),
    do: normalize_parts(document.root, document.bindings, [], [], [], [])

  def normalize(%IntentSet{} = intent_set) do
    normalize_parts(
      intent_set.document.root,
      intent_set.document.bindings,
      intent_set.layouts,
      intent_set.accessibility,
      intent_set.focus,
      intent_set.selections
    )
  end

  def normalize(_output), do: {:error, :invalid_semantic_output}

  @spec identity(Identity.t()) :: tuple()
  def identity(%Identity{} = identity) do
    {:identity, portable(identity.root), Enum.map(identity.path, &portable/1),
     identity.generation}
  end

  defp normalize_parts(root, bindings, layouts, accessibility, focus, selections) do
    {:ok,
     %{
       tree: normalize_node(root),
       bindings: canonical_sort(Enum.map(bindings, &normalize_binding/1)),
       layouts: canonical_sort(Enum.map(layouts, &layout/1)),
       accessibility: canonical_sort(Enum.map(accessibility, &accessibility/1)),
       focus: canonical_sort(Enum.map(focus, &focus/1)),
       selections: canonical_sort(Enum.map(selections, &selection/1))
     }}
  end

  defp normalize_node(%Node{} = node) do
    {:node, node.version, node.kind, identity(node.identity), optional_portable(node.key),
     optional_text(node.content), Enum.map(node.children, &normalize_node/1)}
  end

  defp normalize_binding(%Binding{} = binding) do
    {:binding, binding.event, identity(binding.owner), identity(binding.source)}
  end

  defp layout(%Layout{} = layout) do
    {:layout, layout.version, identity(layout.owner), layout.mode, layout.direction, layout.align,
     metric(layout.gap), padding(layout.padding), metric(layout.width), metric(layout.height),
     optional_metric(layout.min_width), optional_metric(layout.min_height),
     optional_metric(layout.max_width), optional_metric(layout.max_height), layout.grow,
     layout.overflow, virtualization(layout.virtualization)}
  end

  defp accessibility(%Accessibility{} = accessibility) do
    states =
      accessibility.states
      |> Enum.map(fn {key, value} -> {:state, key, value} end)
      |> canonical_sort()

    relationships =
      accessibility.relationships
      |> Enum.map(fn {key, targets} ->
        {:relationship, key, Enum.map(targets, &identity/1)}
      end)
      |> canonical_sort()

    {:accessibility, accessibility.version, identity(accessibility.owner), accessibility.role,
     optional_text(accessibility.name), optional_text(accessibility.description), states,
     relationships, accessibility.live}
  end

  defp focus(%Focus{} = focus) do
    {:focus, focus.version, identity(focus.owner), focus.behavior, optional_integer(focus.order),
     focus.auto_focus, focus.restore, focus.wrap}
  end

  defp selection(%Selection{} = selection) do
    {:selection, selection.version, identity(selection.owner), selection.kind,
     selection_value(selection.kind, selection.value)}
  end

  defp selection_value(:none, nil), do: :none
  defp selection_value(:single, value), do: {:single, portable(value)}
  defp selection_value(:multiple, values), do: {:multiple, Enum.map(values, &portable/1)}

  defp selection_value(:text_range, value) do
    {:text_range, value.anchor, value.focus, value.direction}
  end

  defp metric(value) when value in [:auto, :content, :fill], do: {:metric, value}
  defp metric({:units, value}), do: {:metric, :units, value}
  defp metric({:token, %TokenRef{} = token}), do: {:metric, :token, token(token)}

  defp token(%TokenRef{} = token),
    do: {:token, token.version, token.category, portable(token.name)}

  defp padding({top, right, bottom, left}),
    do: {:padding, metric(top), metric(right), metric(bottom), metric(left)}

  defp virtualization(nil), do: :none

  defp virtualization(value),
    do: {:virtualization, value.axis, metric(value.estimated_extent), value.overscan}

  defp optional_metric(nil), do: :none
  defp optional_metric(value), do: {:some, metric(value)}
  defp optional_text(nil), do: :none
  defp optional_text(value), do: {:some, value}
  defp optional_integer(nil), do: :none
  defp optional_integer(value), do: {:some, value}
  defp optional_portable(nil), do: :none
  defp optional_portable(value), do: {:some, portable(value)}

  defp portable(value) when is_atom(value), do: {:atom, Atom.to_string(value)}
  defp portable(value) when is_binary(value), do: {:binary, value}
  defp portable(value) when is_integer(value), do: {:integer, value}
  defp portable(value) when is_list(value), do: {:list, Enum.map(value, &portable/1)}

  defp portable(value) when is_tuple(value),
    do: {:tuple, value |> Tuple.to_list() |> Enum.map(&portable/1)}

  defp canonical_sort(values),
    do: Enum.sort_by(values, &:erlang.term_to_binary(&1, [:deterministic]))
end
