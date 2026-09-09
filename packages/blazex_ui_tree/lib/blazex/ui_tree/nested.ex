defmodule BlazeX.UITree.Nested do
  @moduledoc """
  In-memory, root-owned nested state with atomic semantic acceptance.

  `mount/6` accepts a trusted static graph with a pure root and nested pure or
  stateful components. `reconcile/6` takes the current revision, same/next root
  generation, reference, graph and explicit same-identity replacement paths.
  `event/3` admits one bound semantic event at the next sequence. Success returns
  `{:ok, session}`; rejected updates return `{:error, diagnostic, exact_prior}`.

  Sessions are opaque trusted in-memory values, not authenticated host data.
  Notifications and disposal plans are observations, not external work. No
  process, renderer commit, effect provider or independent failure boundary.
  """
  alias BlazeX.Component.NestedTable
  alias BlazeX.Component.{Input, Schema}
  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.UITree.{CompositionPlan, IntentSet, NestedCandidates, Node, SemanticAcceptance}
  alias BlazeX.UITree.CompositionPlan, as: Guard

  @keys [
    :table,
    :output,
    :output_digest,
    :graph,
    :reference,
    :boundary,
    :capabilities,
    :notifications,
    :disposals,
    :trace,
    :trace_digest
  ]
  @enforce_keys @keys
  defstruct @keys

  def mount(root, generation, reference, graph, boundary, capabilities \\ []) do
    protect(nil, fn ->
      plan = plan(root, generation, reference, graph, boundary, capabilities)
      transition(nil, plan, graph, reference, boundary, capabilities, 1, 0, MapSet.new(), nil)
    end)
  end

  def reconcile(prior, expected_revision, generation, reference, graph, replacements \\ []) do
    protect(prior, fn ->
      old_plan = validate_prior!(prior, expected_revision)

      Guard.require!(
        generation in [prior.table.root.generation, prior.table.root.generation + 1],
        :generation,
        []
      )

      next =
        plan(
          prior.table.root.root,
          generation,
          reference,
          graph,
          prior.boundary,
          prior.capabilities
        )

      replaced = replacements!(prior, next, replacements)

      transition(
        {prior, old_plan},
        next,
        graph,
        reference,
        prior.boundary,
        prior.capabilities,
        prior.table.revision + 1,
        prior.table.sequence,
        replaced,
        nil
      )
    end)
  end

  def event(prior, expected_revision, event) do
    protect(prior, fn ->
      old_plan = validate_prior!(prior, expected_revision)

      Guard.require!(
        Event.valid?(event) and event.owner == prior.table.root and
          Input.portable?(event.payload),
        :event,
        []
      )

      Guard.require!(
        event.sequence == prior.table.sequence + 1 and NestedTable.counter?(event.sequence),
        :stale_event,
        []
      )

      Guard.require!(
        Enum.any?(
          prior.output.document.bindings,
          &(&1.source == event.source and &1.event == event.name)
        ),
        :unbound_event,
        []
      )

      target =
        prior.table.records
        |> Enum.filter(&(&1.role == :stateful and Identity.contains?(&1.identity, event.source)))
        |> Enum.max_by(&length(&1.identity.path), fn -> nil end)

      Guard.require!(target != nil, :event_target, [])

      transition(
        {prior, old_plan},
        old_plan,
        prior.graph,
        prior.reference,
        prior.boundary,
        prior.capabilities,
        prior.table.revision + 1,
        event.sequence,
        MapSet.new(),
        %{target: target.identity, value: event}
      )
    end)
  end

  defp plan(root, generation, reference, graph, boundary, capabilities),
    do:
      CompositionPlan.build(root, generation, reference, graph, boundary, capabilities, [
        :pure,
        :stateful
      ])
      |> NestedCandidates.preflight()

  defp transition(
         previous,
         plan,
         graph,
         reference,
         boundary,
         capabilities,
         revision,
         sequence,
         replaced,
         event
       ) do
    Guard.require!(
      NestedTable.counter?(revision) and NestedTable.counter?(sequence),
      :counter_overflow,
      []
    )

    old_index = if previous, do: NestedTable.index(elem(previous, 0).table), else: %{}

    {candidate, records, trace, notifications} =
      NestedCandidates.evaluate(plan, old_index, revision, sequence, replaced, event)

    {output, accepted} = SemanticAcceptance.accept(candidate)
    {:ok, nodes} = Node.preorder(output.document.root)
    hashes = Map.new(nodes, &{&1.identity, NestedTable.digest(&1)})
    records = Enum.map(records, &%{&1 | output_digest: Map.fetch!(hashes, &1.identity)})
    {:ok, table} = NestedTable.new(plan.identity, revision, sequence, records)
    {disposals, disposal_trace} = dispose(previous, table, replaced)
    output_digest = NestedTable.digest(output)

    trace =
      trace ++
        accepted ++
        disposal_trace ++
        [
          %{
            event: :accepted,
            revision: revision,
            sequence: sequence,
            table_digest: table.digest,
            output_digest: output_digest
          }
        ]

    {:ok,
     %__MODULE__{
       table: table,
       output: output,
       output_digest: output_digest,
       graph: graph,
       reference: reference,
       boundary: boundary,
       capabilities: capabilities,
       notifications: notifications,
       disposals: disposals,
       trace: trace,
       trace_digest: NestedTable.digest(trace)
     }}
  end

  defp validate_prior!(prior, expected_revision) do
    Guard.require!(
      is_struct(prior, __MODULE__) and
        Enum.sort(Map.keys(Map.from_struct(prior))) == Enum.sort(@keys),
      :prior,
      []
    )

    Guard.require!(
      NestedTable.valid?(prior.table) and prior.table.revision == expected_revision,
      :stale_revision,
      []
    )

    Guard.require!(
      IntentSet.validate(prior.output) == :ok and
        prior.output.document.root.identity == prior.table.root and
        prior.output_digest == NestedTable.digest(prior.output) and
        prior.trace_digest == NestedTable.digest(prior.trace),
      :prior,
      []
    )

    plan =
      plan(
        prior.table.root.root,
        prior.table.root.generation,
        prior.reference,
        prior.graph,
        prior.boundary,
        prior.capabilities
      )

    plans = NestedCandidates.flatten(plan)
    {:ok, nodes} = Node.preorder(prior.output.document.root)
    hashes = Map.new(nodes, &{&1.identity, NestedTable.digest(&1)})

    Guard.require!(
      Enum.map(plans, & &1.identity) == Enum.map(prior.table.records, & &1.identity) and
        map_size(hashes) == length(plans),
      :prior,
      []
    )

    Enum.zip(plans, prior.table.records)
    |> Enum.each(fn {item, record} ->
      Guard.require!(
        record.module == item.module and record.public_id == item.public_id and
          record.role == NestedCandidates.role(item) and
          record.schema_digest == NestedCandidates.fingerprint(item) and
          record.invocation == NestedCandidates.invocation(item) and
          record.output_digest == Map.get(hashes, record.identity),
        :prior,
        item.path
      )
    end)

    plan
  end

  defp replacements!(prior, next, paths) do
    Guard.require!(
      Schema.list?(paths, 128) and length(Enum.uniq(paths)) == length(paths),
      :replacement_paths,
      []
    )

    plans = NestedCandidates.flatten(next)

    if next.identity.generation != prior.table.root.generation do
      Guard.require!(paths == [], :replacement_paths, [])
      MapSet.new(Enum.map(plans, & &1.identity))
    else
      old = NestedTable.index(prior.table)

      changed =
        Enum.filter(plans, fn item ->
          record = Map.get(old, item.identity)
          record != nil and record.schema_digest != NestedCandidates.fingerprint(item)
        end)
        |> Enum.map(& &1.identity.path)

      Guard.require!(
        Enum.all?(paths, &(&1 in changed)) and
          not Enum.any?(paths, fn path ->
            Enum.any?(paths, &(&1 != path and prefix?(&1, path)))
          end),
        :replacement_paths,
        []
      )

      Guard.require!(
        Enum.all?(changed, fn path -> Enum.any?(paths, &prefix?(&1, path)) end),
        :replacement_required,
        []
      )

      plans
      |> Enum.filter(fn item -> Enum.any?(paths, &prefix?(&1, item.identity.path)) end)
      |> Enum.map(& &1.identity)
      |> MapSet.new()
    end
  end

  defp dispose(nil, _table, _replaced), do: {[], []}

  defp dispose({prior, old_plan}, table, replaced) do
    next = NestedTable.index(table)
    plans = Map.new(NestedCandidates.flatten(old_plan), &{&1.identity, &1})

    prior.table.records
    |> Enum.with_index()
    |> Enum.filter(fn {record, _} ->
      record.role == :stateful and
        (not Map.has_key?(next, record.identity) or MapSet.member?(replaced, record.identity))
    end)
    |> Enum.sort_by(fn {record, index} -> {-length(record.identity.path), -index} end)
    |> Enum.map(fn {record, _} ->
      item = Map.fetch!(plans, record.identity)
      called = function_exported?(record.module, :dispose, 1)

      if called do
        input = %{
          item.input
          | transition: :dispose,
            state: record.state,
            revision: table.revision,
            sequence: table.sequence
        }

        Guard.require!(
          NestedCandidates.callback(item, :dispose, input) == :ok,
          :disposal,
          item.path
        )
      end

      reason =
        cond do
          table.root.generation != prior.table.root.generation -> :generation
          MapSet.member?(replaced, record.identity) -> :replaced
          true -> :removed
        end

      plan = %{
        identity: record.identity,
        component: record.public_id,
        reason: reason,
        state_digest: NestedTable.digest(record.state),
        callback: if(called, do: :accepted, else: :absent)
      }

      {plan, %{event: :dispose, component: record.public_id, path: item.path, reason: reason}}
    end)
    |> Enum.unzip()
  end

  defp prefix?(prefix, path), do: is_list(prefix) and Enum.take(path, length(prefix)) == prefix

  defp protect(prior, function) do
    try do
      function.()
    rescue
      _ -> failure(prior, :malformed_transition, [])
    catch
      :throw, {:composition_error, code, path} -> failure(prior, code, path)
      _, _ -> failure(prior, :malformed_transition, [])
    end
  end

  defp failure(prior, code, path) do
    trace = [%{event: :rejected, code: code, path: path}]

    diagnostic = %{
      contract: "0.1.0-bh05-nested-state",
      code: code,
      path: path,
      trace: trace,
      trace_digest: NestedTable.digest(trace)
    }

    if prior == nil, do: {:error, diagnostic}, else: {:error, diagnostic, prior}
  end
end
