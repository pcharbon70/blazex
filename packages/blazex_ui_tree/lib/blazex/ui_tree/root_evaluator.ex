defmodule BlazeX.UITree.RootEvaluator do
  @moduledoc """
  Outward implementation of the Core root evaluator port. Evaluates a trusted
  static graph with a root-role entry and pure/stateful descendants. Preparation
  never disposes accepted components; cleanup is a separate post-commit port.
  Opaque candidate tokens are not application or host-deserializable values.
  """
  @behaviour BlazeX.Component.RootPort.Evaluator
  @behaviour BlazeX.Component.SchedulingPort
  alias BlazeX.Component.{NestedTable, RootPort, RootSchedule}
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{CompositionPlan, IntentSet, NestedCandidates, Node, SemanticAcceptance}

  @impl true
  def prepare(config, request, prior), do: prepare_candidate(config, request, prior, false)

  @impl true
  def prepare_scheduled(config, request, prior) do
    with :ok <- admit(config, request.work, prior),
         true <-
           request.work.kind in [
             :event,
             :message,
             :timer_tick,
             :update,
             :action_result,
             :scope_change,
             :scope_invalidation
           ] do
      prepare_candidate(config, request, prior, true)
    else
      _ -> {:error, :semantic_rejected}
    end
  end

  @impl true
  def admit(config, work, accepted) do
    guarded(fn ->
      validate_candidate(accepted)
      CompositionPlan.require!(RootSchedule.valid_dispatch?(work, accepted), :stale, [])
      target = Enum.find(accepted.token.records, &(Map.from_struct(&1.identity) == work.target))
      callback = callback_name(work, target.role)

      if work.kind in [:scope_change, :scope_invalidation] do
        CompositionPlan.require!(Map.has_key?(config, :scope), :scope, [])

        if work.kind == :scope_change do
          :ok = BlazeX.UITree.ScopedPlan.validate_change!(config.scope, work.payload, accepted)
        else
          CompositionPlan.require!(
            BlazeX.UITree.ScopedPlan.valid_notice?(accepted, work.payload),
            :stale_scope,
            []
          )
        end
      end

      if work.kind not in [:update, :timer_cancel, :scope_change, :scope_invalidation],
        do:
          CompositionPlan.require!(
            function_exported?(target.module, callback, 1),
            :missing_callback,
            []
          )

      if work.kind == :event do
        source = struct(Identity, work.source)

        bound =
          Enum.any?(
            accepted.token.output.document.bindings,
            &(&1.source == source and &1.event == work.name)
          )

        receiver =
          accepted.token.records
          |> Enum.filter(
            &(&1.role in [:root, :stateful] and Identity.contains?(&1.identity, source))
          )
          |> Enum.max_by(&length(&1.identity.path), fn -> nil end)

        CompositionPlan.require!(
          bound and receiver != nil and receiver.identity == target.identity,
          :binding,
          []
        )
      end

      :ok
    end)
  end

  def admit_action(_config, action, candidate) do
    guarded(fn ->
      validate_candidate(candidate)
      target = Enum.find(candidate.token.records, &(Map.from_struct(&1.identity) == action.owner))

      CompositionPlan.require!(
        target != nil and target.role in [:root, :stateful],
        :action_owner,
        []
      )

      if action.kind in [:effect_request, :command] do
        callback = if target.role == :root, do: :effect_result, else: :handle_info

        CompositionPlan.require!(
          function_exported?(target.module, callback, 1),
          :missing_callback,
          []
        )

        if action.kind == :effect_request do
          declarations = target.module.__blazex_component__().declarations.capabilities

          CompositionPlan.require!(
            action.request.declaration.capability in declarations,
            :capability,
            []
          )
        end
      end

      :ok
    end)
  end

  defp prepare_candidate(config, request, prior, scheduled) do
    guarded(fn ->
      %{spec: spec, correlation: correlation, operation: operation} = request
      CompositionPlan.require!(operation in [:mount, :update, :replace], :operation, [])

      CompositionPlan.require!(
        RootPort.correlation?(correlation) and correlation.operation == operation,
        :correlation,
        []
      )

      {:ok, ^spec} = RootPort.normalize(spec)
      CompositionPlan.require!(RootPort.handle(spec) == RootPort.handle(correlation), :owner, [])
      validate_prior(prior, correlation, operation)
      template = Map.fetch!(config.graph, config.reference)

      graph =
        Map.put(config.graph, config.reference, %{
          template
          | module: spec.component,
            public_id: spec.public_id,
            props: spec.props,
            slots: spec.slots
        })

      plan =
        CompositionPlan.build(
          spec.root,
          correlation.generation,
          config.reference,
          graph,
          %{kind: :host, root: spec.root, owner: spec.root},
          spec.capabilities,
          [:root, :pure, :stateful]
        )
        |> NestedCandidates.preflight()

      {plan, scope} =
        if Map.has_key?(config, :scope),
          do: BlazeX.UITree.ScopedPlan.prepare(plan, config.scope, request, prior),
          else: {plan, nil}

      old_index =
        if operation == :update, do: Map.new(prior.token.records, &{&1.identity, &1}), else: %{}

      {candidate, records, trace, notices} =
        NestedCandidates.evaluate(
          plan,
          old_index,
          correlation.revision,
          correlation.sequence,
          MapSet.new(),
          if(scheduled, do: dispatch_event(request.work), else: nil),
          scheduled
        )

      CompositionPlan.require!(scheduled or notices == [], :deferred_actions, [])
      {output, semantic_trace} = SemanticAcceptance.accept(candidate)
      {:ok, nodes} = Node.preorder(output.document.root)
      nodes = Map.new(nodes, &{&1.identity, &1})

      records =
        Enum.map(records, fn record ->
          %{
            record
            | contract: RootPort.version(),
              output_digest: NestedTable.digest(Map.fetch!(nodes, record.identity))
          }
        end)

      token = %{
        plan: plan,
        records: records,
        output: output,
        trace: trace ++ semantic_trace,
        disposals: disposal_plan(records)
      }

      token = if scope, do: Map.put(token, :scope, scope), else: token

      {:ok, accepted} =
        RootPort.candidate(correlation, state(records), NestedTable.digest(output), token)

      if scheduled, do: {:ok, accepted, notices}, else: {:ok, accepted}
    end)
  end

  @impl true
  def cleanup(_config, accepted, reason) when reason in [:replace, :shutdown, :removal] do
    guarded(fn ->
      validate_candidate(accepted)
      plans = Map.new(NestedCandidates.flatten(accepted.token.plan), &{&1.identity, &1})

      Enum.each(accepted.token.disposals, fn item ->
        plan = Map.fetch!(plans, item.identity)
        record = Enum.find(accepted.token.records, &(&1.identity == item.identity))

        if function_exported?(plan.module, item.callback, 1) do
          input = %{
            plan.input
            | transition: item.callback,
              state: record.state,
              payload: {:present, %{reason: reason}},
              revision: record.revision,
              sequence: record.sequence
          }

          :ok = NestedCandidates.callback(plan, item.callback, input, true)
        end
      end)

      :ok
    end)
  end

  def cleanup(_, _, _), do: {:error, :cleanup_failed}

  @impl true
  def cleanup_removed(_config, prior, next) do
    guarded(fn ->
      validate_candidate(prior)
      validate_candidate(next)
      retained = Map.new(next.token.records, &{&1.identity, &1.schema_digest})
      plans = Map.new(NestedCandidates.flatten(prior.token.plan), &{&1.identity, &1})

      Enum.each(prior.token.disposals, fn item ->
        record = Enum.find(prior.token.records, &(&1.identity == item.identity))
        plan = Map.fetch!(plans, item.identity)

        if Map.get(retained, item.identity) != record.schema_digest and
             function_exported?(plan.module, item.callback, 1) do
          input = %{
            plan.input
            | transition: item.callback,
              state: record.state,
              payload: {:present, %{reason: :removal}},
              revision: record.revision,
              sequence: record.sequence
          }

          :ok = NestedCandidates.callback(plan, item.callback, input, true)
        end
      end)

      :ok
    end)
  end

  defp dispatch_event(%{kind: kind}) when kind in [:update, :scope_change, :scope_invalidation],
    do: nil

  defp dispatch_event(%{kind: :action_result} = work) do
    %{
      target: struct(Identity, work.target),
      callback: callback_name(work, if(work.target.path == [], do: :root, else: :stateful)),
      payload: work.payload
    }
  end

  defp dispatch_event(work) do
    payload = %{name: work.name, data: work.payload, source: work.source}

    payload =
      if work.kind == :event,
        do: payload,
        else: Map.put(payload, :kind, if(work.kind == :timer_tick, do: :timer, else: :message))

    %{
      target: struct(Identity, work.target),
      callback: if(work.kind == :event, do: :handle_event, else: :handle_info),
      payload: payload
    }
  end

  defp callback_name(%{kind: :event}, _), do: :handle_event
  defp callback_name(%{kind: :action_result}, :root), do: :effect_result
  defp callback_name(_, _), do: :handle_info

  defp validate_prior(nil, %{operation: :mount, generation: 1, revision: 1}, :mount), do: :ok

  defp validate_prior(prior, correlation, operation) when operation in [:update, :replace] do
    validate_candidate(prior)
    old = prior.correlation

    CompositionPlan.require!(
      RootPort.handle(old) == RootPort.handle(correlation) and
        correlation.sequence > old.sequence,
      :stale,
      []
    )

    if operation == :update,
      do:
        CompositionPlan.require!(
          correlation.generation == old.generation and correlation.revision == old.revision + 1,
          :stale,
          []
        ),
      else:
        CompositionPlan.require!(
          correlation.generation == old.generation + 1 and correlation.revision == 1,
          :stale,
          []
        )
  end

  defp validate_prior(_, _, _), do: CompositionPlan.fail(:prior, [])

  defp validate_candidate(value) do
    CompositionPlan.require!(RootPort.candidate?(value, value.correlation), :candidate, [])

    CompositionPlan.require!(
      IntentSet.validate(value.token.output) == :ok and
        value.output_digest == NestedTable.digest(value.token.output) and
        value.state == state(value.token.records) and
        value.token.disposals == disposal_plan(value.token.records),
      :candidate,
      []
    )
  end

  defp state(records) do
    %{
      components:
        Enum.map(records, fn record ->
          %{
            identity: Map.from_struct(record.identity),
            public_id: record.public_id,
            role: record.role,
            state: record.state,
            invocation: record.invocation,
            contract: record.contract,
            schema_digest: record.schema_digest,
            output_digest: record.output_digest
          }
        end)
    }
  end

  defp disposal_plan(records) do
    records
    |> Enum.with_index()
    |> Enum.filter(fn {r, _} -> r.role in [:stateful, :root] end)
    |> Enum.sort_by(fn {r, index} -> {-length(r.identity.path), -index} end)
    |> Enum.map(fn {r, _} ->
      %{identity: r.identity, callback: if(r.role == :root, do: :terminate, else: :dispose)}
    end)
  end

  defp guarded(fun) do
    fun.()
  rescue
    _ -> {:error, :semantic_rejected}
  catch
    _, _ -> {:error, :semantic_rejected}
  end
end
