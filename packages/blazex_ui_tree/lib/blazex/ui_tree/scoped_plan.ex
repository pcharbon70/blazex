defmodule BlazeX.UITree.ScopedPlan do
  @moduledoc false
  alias BlazeX.Component.{Action, ScopedContext}
  alias BlazeX.UITree.NestedCandidates

  def prepare(plan, config, request, prior) do
    old = if prior && request.operation == :update, do: prior.token.scope.context, else: nil
    work = Map.get(request, :work)
    change = work != nil and work.kind == :scope_change
    invalidation = work != nil and work.kind == :scope_invalidation
    if change, do: validate_change!(config, work.payload, prior)
    if invalidation, do: true = valid_notice?(prior, work.payload)

    components =
      NestedCandidates.flatten(plan)
      |> Enum.filter(&(&1.input != nil))
      |> Enum.map(
        &%{
          identity: Map.from_struct(&1.identity),
          public_id: &1.public_id,
          context_keys: &1.input.context_keys
        }
      )

    live = Enum.map(components, & &1.identity)

    values =
      cond do
        change and Map.has_key?(work.payload, :providers) ->
          work.payload.providers

        old ->
          ScopedContext.provider_values(old) |> Enum.filter(&(&1.owner in live))

        true ->
          Enum.map(config.providers, fn p ->
            true = p.owner.root == request.correlation.root
            %{p | owner: %{p.owner | generation: request.correlation.generation}}
          end)
      end

    {:ok, context} =
      ScopedContext.prepare(
        config.manifest,
        values,
        components,
        request.correlation,
        old,
        change,
        if(invalidation, do: work.payload.consumer, else: nil)
      )

    follow = if not invalidation and old != nil, do: context.pending, else: []
    {attach(plan, context), %{context: context, followups: follow}}
  end

  def ingress(config, payload, accepted) do
    validate_change!(config.scope, payload, accepted)
    work(accepted, :scope_change, payload)
  rescue
    _ -> {:error, :invalid_scope_change}
  end

  def validate_change!(config, payload, accepted) do
    if Map.has_key?(payload, :selection),
      do: BlazeX.UITree.RegistryPlan.validate_select!(config, payload, accepted),
      else: validate_providers!(config, payload, accepted)
  end

  defp validate_providers!(config, payload, accepted) do
    true = Action.keys?(payload, [:scope_version, :root, :generation, :revision, :providers])
    true = payload.scope_version == 1 and payload.root == accepted.correlation.root
    true = payload.generation == accepted.correlation.generation
    true = payload.revision == accepted.token.scope.context.revision
    true = is_list(payload.providers) and length(payload.providers) <= 32
    true = Action.public?(payload) and Action.size?(payload, 65_536)

    before = ScopedContext.provider_values(accepted.token.scope.context)
    changed = (payload.providers -- before) ++ (before -- payload.providers)

    Enum.each(changed, fn p ->
      true = config.manifest.definitions[p.name].boundary == config.boundary
    end)

    :ok
  end

  def followups(candidate) do
    scope = candidate.token.scope

    Enum.map(scope.followups, fn consumer ->
      work(candidate, :scope_invalidation, %{
        root: candidate.correlation.root,
        generation: candidate.correlation.generation,
        revision: scope.context.revision,
        consumer: consumer,
        digest: ScopedContext.stamp(scope.context, consumer)
      })
    end)
  end

  def valid_notice?(accepted, payload) do
    s = accepted.token.scope.context

    Action.keys?(payload, [:root, :generation, :revision, :consumer, :digest]) and
      payload.root == s.root and payload.generation == s.generation and
      payload.revision == s.revision and
      payload.consumer in s.pending and payload.digest == ScopedContext.stamp(s, payload.consumer)
  rescue
    _ -> false
  end

  defp work(candidate, kind, payload) do
    root = Enum.find(candidate.state.components, &(&1.role == :root))

    %{
      class: :message,
      producer: "scope",
      sequence: candidate.correlation.sequence,
      generation: candidate.correlation.generation,
      revision: candidate.correlation.revision,
      source: root.identity,
      target: root.identity,
      route: :self,
      name: "scope",
      payload: payload,
      supersedable: false,
      timer: :none,
      receipt: 0,
      source_stamp: root.schema_digest,
      target_stamp: root.schema_digest,
      kind: kind,
      origin: :scope
    }
  end

  defp attach(plan, scope) do
    plan =
      if plan.input,
        do: %{
          plan
          | input:
              Map.put(
                plan.input,
                :contexts,
                ScopedContext.values(scope, Map.from_struct(plan.identity))
              )
        },
        else: plan

    %{plan | children: Enum.map(plan.children, &attach(&1, scope))}
  end
end
