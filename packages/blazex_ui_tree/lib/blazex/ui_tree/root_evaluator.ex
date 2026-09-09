defmodule BlazeX.UITree.RootEvaluator do
  @moduledoc """
  Outward implementation of the Core root evaluator port. Evaluates a trusted
  static graph with a root-role entry and pure/stateful descendants. Preparation
  never disposes accepted components; cleanup is a separate post-commit port.
  Opaque candidate tokens are not application or host-deserializable values.
  """
  @behaviour BlazeX.Component.RootPort.Evaluator
  alias BlazeX.Component.{NestedTable, RootPort}
  alias BlazeX.UITree.{CompositionPlan, IntentSet, NestedCandidates, Node, SemanticAcceptance}

  @impl true
  def prepare(config, request, prior) do
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

      old_index =
        if operation == :update, do: Map.new(prior.token.records, &{&1.identity, &1}), else: %{}

      {candidate, records, trace, notices} =
        NestedCandidates.evaluate(plan, old_index, correlation.revision, correlation.sequence)

      CompositionPlan.require!(notices == [], :deferred_actions, [])
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

      RootPort.candidate(correlation, state(records), NestedTable.digest(output), token)
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
