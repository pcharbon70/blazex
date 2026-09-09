defmodule BlazeX.UITree.RegistryPlan do
  @moduledoc false
  alias BlazeX.Component.{Action, ComponentRegistry}

  def resolve(config, request, prior) do
    if Map.has_key?(config.scope, :registry) do
      registry = config.scope.registry
      true = is_map(config.scope.calls) and map_size(config.scope.calls) <= 128
      true = not Map.has_key?(config.scope.calls, config.reference)
      true = registry.root == request.spec.root
      previous = if prior && request.operation == :update, do: prior.token.scope, else: nil
      true = previous == nil or previous.registry_generation == registry.generation
      initial = Map.new(config.scope.calls, fn {site, call} -> {site, call.initial} end)
      selection = if previous, do: previous.selection, else: initial
      payload = if Map.has_key?(request, :work), do: request.work.payload, else: %{}

      selection =
        if Map.has_key?(payload, :selection) do
          validate_select!(config.scope, payload, prior)
          Map.merge(selection, payload.selection)
        else
          selection
        end

      {graph, outcomes} =
        Enum.reduce(Enum.sort(config.scope.calls), {config.graph, []}, fn {site, call},
                                                                          {graph, outcomes} ->
          true = Action.keys?(call, [:allowed, :role, :schema_version, :fallback, :initial])

          true =
            is_list(call.allowed) and length(call.allowed) <= 128 and
              Enum.uniq(call.allowed) == call.allowed

          template = Map.fetch!(graph, site)

          requested = %{
            id: Map.fetch!(selection, site),
            role: call.role,
            schema_version: call.schema_version,
            generation: registry.generation,
            props: template.props,
            slots: template.slots
          }

          boundary = %{kind: :host, root: request.spec.root, owner: request.spec.root}

          {entry, status} =
            case ComponentRegistry.lookup(registry, requested, call.allowed, boundary) do
              {:ok, entry, _} ->
                {entry, :selected}

              _ ->
                true = is_binary(call.fallback) and call.fallback in call.allowed

                {:ok, fallback, _} =
                  ComponentRegistry.lookup(
                    registry,
                    %{requested | id: call.fallback},
                    call.allowed,
                    boundary
                  )

                {fallback, :fallback}
            end

          true = Enum.all?(entry.capabilities, &(&1 in request.spec.capabilities))
          true = Enum.all?(entry.contexts, &Map.has_key?(config.scope.manifest.definitions, &1))
          graph = Map.put(graph, site, %{template | module: entry.module, public_id: entry.id})

          {graph,
           outcomes ++
             [%{site: site, requested: requested.id, selected: entry.id, status: status}]}
        end)

      {graph,
       %{
         selection: selection,
         registry_generation: registry.generation,
         registry_outcomes: outcomes
       }}
    else
      {config.graph, %{selection: %{}, registry_generation: nil, registry_outcomes: []}}
    end
  end

  def validate_select!(config, payload, accepted) do
    true =
      Action.keys?(payload, [
        :scope_version,
        :root,
        :generation,
        :revision,
        :selection,
        :registry_generation
      ])

    true = payload.scope_version == 1 and payload.root == accepted.correlation.root

    true =
      payload.generation == accepted.correlation.generation and
        payload.revision == accepted.token.scope.context.revision

    true = payload.registry_generation == config.registry.generation
    true = Action.public?(payload) and Action.size?(payload, 65_536)
    true = is_map(payload.selection) and map_size(payload.selection) in 1..128

    true =
      Enum.all?(payload.selection, fn {site, id} ->
        Map.has_key?(config.calls, site) and is_binary(id) and byte_size(id) in 1..64
      end)

    :ok
  end
end
