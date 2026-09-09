defmodule BlazeX.UITree.SemanticAcceptance do
  @moduledoc false
  alias BlazeX.Component.Input

  alias BlazeX.UITree.{
    Accessibility,
    Binding,
    CompositionPlan,
    Document,
    Focus,
    IntentSet,
    Layout,
    Node,
    Selection
  }

  @keys [
    :kind,
    :content,
    :bindings,
    :layout,
    :accessibility,
    :focus,
    :selection,
    :required_capabilities
  ]

  def accept(candidate) do
    candidates = flatten(candidate)
    identities = Map.new(candidates, &{&1.identity.path, &1.identity})
    root = candidate.identity
    node = build_node(candidate)

    bindings =
      Enum.flat_map(candidates, fn item ->
        events = Map.get(item.output, :bindings, [])
        CompositionPlan.require!(is_list(events), :bindings, item.path)
        Enum.map(events, &unwrap(Binding.new(&1, root, item.identity), :binding, item.path))
      end)

    document = unwrap(Document.new(node, bindings), :document, [])

    annotations =
      Enum.reduce(
        candidates,
        [layouts: [], accessibility: [], focus: [], selections: []],
        fn item, all ->
          all
          |> append(:layouts, intent(item, :layout, identities))
          |> append(:accessibility, intent(item, :accessibility, identities))
          |> append(:focus, intent(item, :focus, identities))
          |> append(:selections, intent(item, :selection, identities))
        end
      )

    output = unwrap(IntentSet.new(document, annotations), :intent_set, [])

    trace =
      Enum.map(
        candidates,
        &%{event: :semantic_node_accepted, component: &1.public_id, path: &1.path}
      )

    {output, trace}
  end

  defp flatten(candidate), do: [candidate | Enum.flat_map(candidate.children, &flatten/1)]

  defp build_node(item) do
    output = item.output

    CompositionPlan.require!(
      Enum.all?(Map.keys(output), &(&1 in @keys)),
      :candidate_fields,
      item.path
    )

    required = Map.get(output, :required_capabilities, [])

    CompositionPlan.require!(
      Input.names?(required) and Enum.all?(required, &(&1 in item.capabilities)),
      :undeclared_capability,
      item.path
    )

    children = Enum.map(item.children, &build_node/1)

    unwrap(
      Node.new(Map.get(output, :kind), item.identity,
        content: Map.get(output, :content),
        children: children
      ),
      :semantic_node,
      item.path
    )
  end

  defp append(all, _key, nil), do: all
  defp append(all, key, value), do: Keyword.update!(all, key, &(&1 ++ [value]))

  defp intent(item, key, identities) do
    if Map.has_key?(item.output, key) do
      spec = Map.fetch!(item.output, key)
      CompositionPlan.require!(is_map(spec) and not is_struct(spec), :intent, item.path)

      result =
        case key do
          :layout ->
            Layout.new(item.identity, spec[:mode], options(spec, :mode))

          :focus ->
            Focus.new(item.identity, spec[:behavior], options(spec, :behavior))

          :selection ->
            CompositionPlan.require!(
              Enum.all?(Map.keys(spec), &(&1 in [:kind, :value])),
              :selection,
              item.path
            )

            Selection.new(item.identity, spec[:kind], spec[:value])

          :accessibility ->
            relationships = Map.get(spec, :relationships, %{})

            CompositionPlan.require!(
              is_map(relationships) and not is_struct(relationships),
              :relationship,
              item.path
            )

            relationships =
              Map.new(relationships, fn {name, paths} ->
                CompositionPlan.require!(is_list(paths), :relationship, item.path)

                {name,
                 Enum.map(paths, fn path ->
                   case Map.fetch(identities, path) do
                     {:ok, identity} -> identity
                     :error -> CompositionPlan.fail(:relationship_target, item.path)
                   end
                 end)}
              end)

            Accessibility.new(
              item.identity,
              spec[:role],
              options(Map.put(spec, :relationships, relationships), :role)
            )
        end

      unwrap(result, key, item.path)
    end
  end

  defp options(spec, tag), do: spec |> Map.delete(tag) |> Enum.sort()
  defp unwrap({:ok, value}, _code, _path), do: value
  defp unwrap(_, code, path), do: CompositionPlan.fail(code, path)
end
