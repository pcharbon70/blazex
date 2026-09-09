defmodule BlazeX.UITree.CompositionPlan do
  @moduledoc false
  alias BlazeX.Component.{Invocation, Schema}
  alias BlazeX.Core.Identity
  @keys [:module, :public_id, :site, :key, :props, :slots, :children]

  def build(root, generation, reference, graph, boundary, capabilities, roles \\ [:pure]) do
    require!(roles in [[:pure], [:pure, :stateful]], :roles, [])
    require!(Schema.boundary?(boundary) and boundary.root == root, :boundary, [])
    require!(BlazeX.Component.Input.names?(capabilities), :capabilities, [])
    require!(is_integer(generation) and generation in 1..9_007_199_254_740_991, :generation, [])
    require!(is_map(graph) and not is_struct(graph) and map_size(graph) in 1..128, :graph, [])
    require!(Enum.all?(Map.keys(graph), &Schema.name?/1), :graph, [])
    {:ok, identity} = Identity.new(root, generation)

    {plan, state} =
      visit(
        reference,
        identity,
        graph,
        boundary,
        capabilities,
        [],
        [],
        nil,
        %{},
        %{count: 0, nodes: 0, seen: MapSet.new(), used: MapSet.new(), roles: roles},
        nil
      )

    require!(MapSet.size(state.used) == map_size(graph), :unreachable_record, [])
    plan
  end

  defp visit(
         ref,
         identity,
         graph,
         boundary,
         capabilities,
         stack,
         path,
         caller,
         lexical_props,
         state,
         override
       ) do
    require!(
      length(identity.path) <= 12 and state.count < 128 and state.nodes < 256,
      :limit,
      path
    )

    require!(ref not in stack, :cycle, path)
    spec = Map.get(graph, ref)

    require!(
      is_map(spec) and not is_struct(spec) and Enum.sort(Map.keys(spec)) == Enum.sort(@keys),
      :record,
      path
    )

    require!(
      Schema.name?(spec.public_id) and Schema.name?(spec.site) and key?(spec.key),
      :call_identity,
      path
    )

    require!(Schema.list?(spec.children, 128), :children, path)
    require!(not MapSet.member?(state.seen, identity), :duplicate_identity, path)

    require!(
      is_atom(spec.module) and Code.ensure_loaded?(spec.module) and
        function_exported?(spec.module, :__blazex_component__, 0) and
        function_exported?(spec.module, :render, 1),
      :component,
      path
    )

    metadata = spec.module.__blazex_component__()

    require!(
      is_map(metadata) and metadata.role in state.roles and metadata.version == Schema.version() and
        valid_callbacks?(metadata) and (metadata.role == :pure or identity.path != []),
      :pure_contract,
      path
    )

    required_caps = metadata.declarations.capabilities
    require!(Enum.all?(required_caps, &(&1 in capabilities)), :capability_unavailable, path)
    props = if override, do: override, else: spec.props

    invocation =
      case Invocation.normalize(metadata.schema.declarations, props, spec.slots, boundary) do
        {:ok, value} -> value
        {:error, _} -> fail(:invocation, path)
      end

    state = %{
      state
      | count: state.count + 1,
        nodes: state.nodes + 1,
        seen: MapSet.put(state.seen, identity),
        used: MapSet.put(state.used, ref)
    }

    {children, state} =
      spec.children
      |> Enum.with_index()
      |> Enum.map_reduce(state, fn {child, index}, current ->
        child_spec = Map.get(graph, child)
        require!(is_map(child_spec), :child_reference, path ++ [index])

        child_identity =
          child_identity(identity, child_spec, :child, child_spec[:key], path ++ [index])

        visit(
          child,
          child_identity,
          graph,
          boundary,
          capabilities,
          [ref | stack],
          path ++ [index],
          spec.public_id,
          invocation.props,
          current,
          nil
        )
      end)

    lexical_owner = caller || spec.public_id
    lexical_props = if caller, do: lexical_props, else: invocation.props

    {slot_children, state} =
      invocation.slots
      |> Enum.with_index()
      |> Enum.map_reduce(state, fn {{name, entries}, slot_index}, current ->
        Enum.with_index(entries)
        |> Enum.map_reduce(current, fn {entry, entry_index}, inner ->
          slot_path = path ++ [length(children) + slot_index, entry_index]
          require!(length(identity.path) + 1 <= 12 and inner.nodes < 256, :limit, slot_path)

          case entry.content do
            %{"owner" => owner, "caller" => ^lexical_owner, "id" => content_ref}
            when owner == identity.root ->
              template = Map.get(graph, content_ref)
              require!(is_map(template), :slot_reference, slot_path)
              child_id = child_identity(identity, template, name, entry.key, slot_path)

              props =
                Map.new(template.props, fn
                  {key, {:caller, field}} ->
                    require!(Map.has_key?(lexical_props, field), :lexical_prop, slot_path)
                    {key, Map.fetch!(lexical_props, field)}

                  pair ->
                    pair
                end)
                |> Map.merge(entry.props)

              props =
                if entry.context == %{}, do: props, else: Map.put(props, "context", entry.context)

              {child, inner} =
                visit(
                  content_ref,
                  child_id,
                  graph,
                  boundary,
                  capabilities,
                  [ref | stack],
                  path ++ [length(children) + slot_index, entry_index],
                  lexical_owner,
                  lexical_props,
                  inner,
                  props
                )

              {%{child | slot: name}, inner}

            %{"kind" => "text", "value" => text} ->
              data_slot(identity, name, entry.key, text, slot_path, inner)

            %{"kind" => "number", "value" => number} ->
              data_slot(identity, name, entry.key, Integer.to_string(number), slot_path, inner)

            %{"kind" => "boolean", "value" => flag} ->
              data_slot(identity, name, entry.key, Atom.to_string(flag), slot_path, inner)

            _ ->
              fail(:lexical_owner, slot_path)
          end
        end)
      end)

    input = %{
      role: metadata.role,
      transition: :render,
      props: invocation.props,
      slots: Map.new(invocation.slots),
      state: :absent,
      payload: :absent,
      root: %{root: identity.root, path: [], generation: identity.generation},
      identity: Map.from_struct(identity),
      generation: identity.generation,
      revision: 0,
      sequence: 0,
      capabilities: required_caps,
      context_keys: metadata.declarations.context
    }

    {%{
       module: spec.module,
       metadata: metadata,
       public_id: spec.public_id,
       identity: identity,
       input: input,
       children: children ++ List.flatten(slot_children),
       path: path,
       slot: nil,
       data: nil
     }, state}
  end

  defp key?(key), do: is_binary(key) and byte_size(key) in 1..128 and String.valid?(key)

  defp valid_callbacks?(%{role: :pure, callbacks: callbacks}), do: callbacks == [render: 1]

  defp valid_callbacks?(%{role: :stateful, callbacks: callbacks}) do
    {required, optional} =
      {[init: 1, render: 1], [update: 1, handle_event: 1, handle_info: 1, replace: 1, dispose: 1]}

    Enum.all?(required, &(&1 in callbacks)) and
      Enum.all?(callbacks, &(&1 in (required ++ optional)))
  end

  defp valid_callbacks?(_), do: false

  defp child_identity(parent, spec, slot, key, path) do
    require!(Schema.name?(spec[:public_id]) and Schema.name?(spec[:site]), :call_identity, path)
    segment = {spec.public_id, spec.site, slot, key}

    case Identity.child(parent, segment) do
      {:ok, value} -> value
      _ -> fail(:identity, path)
    end
  end

  defp data_slot(parent, name, key, text, path, state) do
    {:ok, identity} = Identity.child(parent, {:slot, name, key})
    require!(not MapSet.member?(state.seen, identity), :duplicate_identity, path)

    value = %{
      module: nil,
      metadata: nil,
      public_id: "slot",
      identity: identity,
      input: nil,
      children: [],
      path: path,
      slot: name,
      data: %{kind: :text, content: text}
    }

    {value, %{state | nodes: state.nodes + 1, seen: MapSet.put(state.seen, identity)}}
  end

  def require!(true, _code, _path), do: :ok
  def require!(false, code, path), do: fail(code, path)
  def fail(code, path), do: throw({:composition_error, code, path})
end
