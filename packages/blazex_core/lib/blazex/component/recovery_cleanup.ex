defmodule BlazeX.Component.RecoveryCleanup do
  @moduledoc "Deadline-bound owner cleanup; failed release is never silently counted as success."
  alias BlazeX.Component.{ActionLedger, CleanupOutcome, RecoveryPort, RootProcess}

  @deadline_ms 1000

  def run(state, reason, next \\ nil), do: execute_root(state, reason, next, now())

  defp execute_root(state, reason, next, started) do
    deadline = started + @deadline_ms
    runtime_before = runtime_metrics()
    {:ok, session} = RecoveryPort.open_session()

    try do
      execute_root_with_session(state, reason, next, started, deadline, session, runtime_before)
    after
      RecoveryPort.close_session(session)
    end
  rescue
    _ -> failed(state, started)
  catch
    _, _ -> failed(state, started)
  end

  defp execute_root_with_session(state, reason, next, started, deadline, session, runtime_before) do
    planning_started = now()

    retained =
      if next, do: Map.new(next.state.components, &{&1.identity, &1.schema_digest}), else: %{}

    previous =
      if state.accepted,
        do: Map.new(state.accepted.state.components, &{&1.identity, &1.schema_digest}),
        else: %{}

    selected = fn id -> next == nil or Map.get(retained, id) != Map.get(previous, id) end

    generation =
      if state.accepted,
        do: state.accepted.correlation.generation,
        else: state.recovery.generation

    owner = %{root: state.spec.root, generation: generation, path: []}
    state = if next, do: state, else: RootProcess.recovery_close(state, reason)

    pending =
      if state.pending,
        do: [job(owner, :candidate, state.ports.renderer, :cancel, state.pending.correlation)],
        else: []

    if state.pending && state.pending.timer, do: Process.cancel_timer(state.pending.timer)
    actions = state.actions

    requests =
      if actions, do: Enum.sort_by(Map.values(actions.ledger.pending), & &1.correlation), else: []

    requests = Enum.filter(requests, &selected.(&1.action.owner))
    canceled = Enum.map(requests, & &1.correlation)

    if actions,
      do:
        Enum.each(actions.timers, fn {key, timer} ->
          if next == nil or key in canceled, do: Process.cancel_timer(timer.reference)
        end)

    cancellations = Enum.map(requests, &job(&1.action.owner, :request, actions.port, :cancel, &1))
    planning_ms = now() - planning_started
    cancellations_started = now()
    {rows, session} = execute(pending ++ cancellations, [], deadline, session)
    cancellations_ms = now() - cancellations_started

    owner_discovery_started = now()

    {owners, session} =
      if state.accepted &&
           state.recovery.cleaned_generation != state.accepted.correlation.generation,
         do: invoke(session, state.ports.evaluator, :cleanup_owners, [state.accepted], deadline),
         else: {[], session}

    owner_discovery_ms = now() - owner_discovery_started

    component_jobs =
      if is_list(owners) and length(owners) <= 128 do
        owners
        |> Enum.filter(selected)
        |> Enum.map(fn id ->
          true =
            BlazeX.Component.RootSchedule.identity?(id) and id.root == owner.root and
              id.generation == generation

          %{
            owner: id,
            kind: :component,
            port: state.ports.evaluator,
            callback: :cleanup_owner,
            arguments: [state.accepted, id, reason],
            reference: id
          }
        end)
      else
        [
          %{
            owner: owner,
            kind: :component,
            port: state.ports.evaluator,
            callback: :invalid_cleanup,
            arguments: [],
            reference: owner
          }
        ]
      end

    component_started = now()
    {rows, session} = execute(component_jobs, rows, deadline, session)
    component_ms = now() - component_started
    lease_planning_started = now()
    leases = if actions, do: ActionLedger.ordered_leases(actions.ledger), else: []
    leases = Enum.filter(leases, &selected.(&1.owner))

    lease_planning_ms = now() - lease_planning_started

    lease_pages_before = session.pages_sent
    lease_started = now()

    prefix_pages = rows |> Enum.reverse() |> CleanupOutcome.operation_pages()

    {lease_pages, lease_candidates, session} =
      execute_leases(leases, if(actions, do: actions.port, else: nil), deadline, session)

    lease_ms = now() - lease_started
    lease_pages_sent = session.pages_sent - lease_pages_before

    request = %{root: owner.root, generation: generation, reason: reason, restore_focus: true}

    renderer_started = now()

    {suffix_rows, session} =
      execute(
        if(next, do: [], else: [job(owner, :renderer, state.ports.renderer, :dispose, request)]),
        [],
        deadline,
        session
      )

    renderer_ms = now() - renderer_started

    suffix_rows = Enum.reverse(suffix_rows)
    normal_stats = RecoveryPort.session_stats(session)
    RecoveryPort.close_session(session)
    forced_started = now()

    {suffix_rows, lease_pages, forced_stats, forced_worker_starts} =
      force(suffix_rows, lease_pages, lease_candidates, deadline)

    forced_ms = now() - forced_started
    pages = prefix_pages ++ lease_pages ++ CleanupOutcome.operation_pages(suffix_rows)
    counts = CleanupOutcome.counts(pages)
    outcome_format = CleanupOutcome.representation(pages)
    prior = state.recovery.cleanup
    prior_unresolved = if prior, do: prior.unresolved, else: 0
    unresolved = max(counts.unresolved, prior_unresolved)
    finalization_started = now()

    actions =
      if actions do
        ledger =
          Enum.reduce(requests, actions.ledger, fn entry, acc ->
            ActionLedger.record(acc, :canceled, entry.correlation)
          end)

        true = CleanupOutcome.matches_leases?(lease_pages, leases)

        ledger =
          ActionLedger.released_ordered(
            ledger,
            leases,
            CleanupOutcome.terminal_statuses(lease_pages)
          )

        pending = Map.drop(ledger.pending, canceled)
        timers = if next, do: Map.drop(actions.timers, canceled), else: %{}
        %{actions | ledger: %{ledger | pending: pending}, timers: timers}
      else
        nil
      end

    finalization_ms = now() - finalization_started
    elapsed = now() - started
    runtime_after = runtime_metrics()

    report = %{
      status: if(unresolved == 0, do: :completed, else: :failed),
      elapsed_ms: elapsed,
      exceeded_deadline: elapsed > @deadline_ms,
      unresolved: unresolved,
      failed: counts.failed,
      timed_out: counts.timed_out,
      forced: counts.forced,
      callback_failures: CleanupOutcome.callback_failures(pages),
      requested: counts.requested,
      pages: pages,
      outcome_format: outcome_format,
      amplification:
        amplification(normal_stats, forced_stats, forced_worker_starts, lease_pages_sent),
      runtime_metrics: metric_observation(runtime_before, runtime_after),
      stage_timings_ms: %{
        planning: planning_ms,
        cancellations: cancellations_ms,
        owner_discovery: owner_discovery_ms,
        component_cleanup: component_ms,
        lease_planning: lease_planning_ms,
        lease_release: lease_ms,
        renderer_disposal: renderer_ms,
        forced_cleanup: forced_ms,
        ledger_finalization: finalization_ms,
        total: elapsed
      }
    }

    # A later empty ledger cannot prove release of an earlier lost resource.
    # Retain the first unresolved inventory without recursively growing reports.
    report =
      if prior_unresolved > 0,
        do: Map.put(report, :unresolved_pages, Map.get(prior, :unresolved_pages, prior.pages)),
        else: report

    cleaned = if next, do: state.recovery.cleaned_generation, else: generation

    %{
      state
      | pending: nil,
        actions: actions,
        recovery: %{state.recovery | cleanup: report, cleaned_generation: cleaned}
    }
  end

  defp execute(jobs, rows, deadline, session) do
    {records, session} = call_jobs(jobs, deadline, session)

    next =
      Enum.reduce(records, rows, fn {job, result, elapsed}, acc ->
        reference = if job.kind == :lease, do: ActionLedger.lease_ref(job.reference), else: nil
        status = status(result)

        row = %{
          owner: job.owner,
          kind: job.kind,
          reference: reference,
          requested: true,
          status: status,
          force_status: :not_requested,
          elapsed_ms: elapsed,
          unresolved: false
        }

        row =
          if job.kind != :component and status != :completed,
            do: Map.merge(row, %{force_reference: job.reference, port: job.port}),
            else: row

        [row | acc]
      end)

    {next, session}
  end

  defp execute_leases(leases, port, deadline, session) do
    leases
    |> Enum.chunk_every(RecoveryPort.page_size())
    |> Enum.with_index()
    |> Enum.reduce({[], [], session}, fn {page, page_index}, {pages, candidates, current} ->
      started = now()
      timeout = min(port_timeout(port), deadline - started)

      {results, next} =
        if timeout > 0 do
          {release_port, _} = unwrap_port(port)

          requests =
            Enum.map(page, fn lease ->
              {release_port, :release, [%{lease | release_requested: true}]}
            end)

          case RecoveryPort.page(current, requests, timeout) do
            {:ok, values, updated} -> {values, updated}
            {:error, error, updated} -> {List.duplicate({:error, error}, length(page)), updated}
          end
        else
          {List.duplicate({:error, :timed_out}, length(page)), current}
        end

      elapsed = now() - started

      statuses = Enum.map(results, &status/1)
      outcome = CleanupOutcome.lease_page(page, statuses, elapsed)

      next_candidates =
        page
        |> Enum.zip(statuses)
        |> Enum.with_index()
        |> Enum.reduce(candidates, fn
          {{_lease, :completed}, _item_index}, acc ->
            acc

          {{lease, _status}, item_index}, acc ->
            [
              %{
                target: {:lease, page_index, item_index},
                owner: lease.owner,
                kind: :lease,
                port: port,
                reference: lease
              }
              | acc
            ]
        end)

      {pages ++ [outcome], next_candidates, next}
    end)
  end

  defp invoke(session, port, callback, arguments, deadline) do
    internal = %{
      owner: nil,
      kind: :internal,
      port: port,
      callback: callback,
      arguments: arguments,
      reference: nil
    }

    case call_jobs([internal], deadline, session) do
      {[{_, result, _}], next} -> {result, next}
      {_, next} -> {{:error, :port_failed}, next}
    end
  end

  defp call_jobs(jobs, deadline, session) do
    jobs
    |> Enum.chunk_every(RecoveryPort.page_size())
    |> Enum.reduce({[], session}, fn page, {records, current} ->
      started = now()
      timeout = page_timeout(page, deadline)

      {results, next} =
        if timeout > 0 do
          case RecoveryPort.page(current, Enum.map(page, &session_request/1), timeout) do
            {:ok, values, updated} -> {values, updated}
            {:error, error, updated} -> {List.duplicate({:error, error}, length(page)), updated}
          end
        else
          {List.duplicate({:error, :timed_out}, length(page)), current}
        end

      elapsed = now() - started
      {records ++ Enum.zip_with(page, results, &{&1, &2, elapsed}), next}
    end)
  end

  defp force(rows, lease_pages, lease_candidates, deadline) do
    row_candidates =
      rows
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {row, index} when row.kind != :component and row.status != :completed ->
          [
            %{
              target: {:row, index},
              owner: row.owner,
              kind: row.kind,
              port: row.port,
              reference: row.force_reference
            }
          ]

        _ ->
          []
      end)

    candidates = Enum.reverse(lease_candidates) ++ row_candidates

    cond do
      candidates == [] ->
        {apply_force_rows(rows, %{}), lease_pages, empty_stats(), 0}

      deadline - now() <= 0 ->
        updates = Map.new(candidates, &{&1.target, :timed_out})
        apply_force_updates(rows, lease_pages, updates, empty_stats(), 0)

      true ->
        {:ok, session} = RecoveryPort.open_session()

        jobs =
          Enum.map(candidates, fn candidate ->
            %{
              owner: candidate.owner,
              kind: :force,
              port: candidate.port,
              callback: :force_cleanup,
              arguments: [
                %{
                  kind: candidate.kind,
                  owner: candidate.owner,
                  reference: candidate.reference
                }
              ],
              reference: candidate.target
            }
          end)

        try do
          {records, updated} = call_jobs(jobs, deadline, session)
          stats = RecoveryPort.session_stats(updated)
          updates = Map.new(records, fn {job, result, _} -> {job.reference, status(result)} end)
          apply_force_updates(rows, lease_pages, updates, stats, 1)
        after
          RecoveryPort.close_session(session)
        end
    end
  end

  defp apply_force_updates(rows, lease_pages, updates, stats, worker_starts) do
    lease_updates =
      Enum.reduce(updates, %{}, fn
        {{:lease, page_index, item_index}, value}, acc ->
          Map.update(acc, page_index, %{item_index => value}, &Map.put(&1, item_index, value))

        _, acc ->
          acc
      end)

    pages =
      lease_pages
      |> Enum.with_index()
      |> Enum.map(fn {page, index} ->
        CleanupOutcome.apply_force(page, Map.get(lease_updates, index, %{}))
      end)

    row_updates =
      Map.new(updates, fn
        {{:row, index}, value} -> {index, value}
        {other, value} -> {other, value}
      end)

    {apply_force_rows(rows, row_updates), pages, stats, worker_starts}
  end

  defp apply_force_rows(rows, indexes) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      force_status = Map.get(indexes, index, :not_requested)

      row
      |> Map.put(:force_status, force_status)
      |> Map.put(
        :unresolved,
        row.kind != :component and row.status != :completed and force_status != :completed
      )
      |> Map.drop([:port, :force_reference])
    end)
  end

  defp amplification(normal, forced, forced_worker_starts, lease_pages_sent) do
    %{
      page_size: RecoveryPort.page_size(),
      maximum_page_size: RecoveryPort.maximum_page_size(),
      normal_worker_starts: 1,
      forced_worker_starts: forced_worker_starts,
      total_worker_starts: 1 + forced_worker_starts,
      peak_live_cleanup_workers: 1,
      lease_pages_sent: lease_pages_sent,
      normal: normal,
      forced: forced,
      protocol_messages:
        normal.messages_sent + normal.messages_received + forced.messages_sent +
          forced.messages_received,
      callbacks_attempted: normal.jobs_sent + forced.jobs_sent,
      callbacks_completed: normal.results_received + forced.results_received
    }
  end

  defp page_timeout(page, deadline) do
    declared = page |> Enum.map(&port_timeout(&1.port)) |> Enum.max(fn -> 100 end)
    min(declared, deadline - now())
  end

  defp session_request(job) do
    {port, _} = unwrap_port(job.port)
    {port, job.callback, job.arguments}
  end

  defp port_timeout(port), do: elem(unwrap_port(port), 1)
  defp unwrap_port({RecoveryPort, {port, timeout}}), do: {port, timeout}
  defp unwrap_port(port), do: {port, 100}

  defp empty_stats,
    do: %{
      pages_sent: 0,
      pages_received: 0,
      jobs_sent: 0,
      results_received: 0,
      messages_sent: 0,
      messages_received: 0,
      request_bytes: 0,
      result_bytes: 0,
      page_durations_ms: []
    }

  defp job(owner, kind, port, callback, reference),
    do: %{
      owner: owner,
      kind: kind,
      port: port,
      callback: callback,
      arguments: [reference],
      reference: reference
    }

  defp status(result) when result in [:ok, :released], do: :completed
  defp status({:error, :timed_out}), do: :timed_out
  defp status(_), do: :failed
  defp now, do: System.monotonic_time(:millisecond)

  defp runtime_metrics do
    %{
      process_count: safe_metric(fn -> :erlang.system_info(:process_count) end),
      owner_memory_bytes:
        safe_metric(fn ->
          {:memory, bytes} = Process.info(self(), :memory)
          bytes
        end),
      runtime_memory_bytes: safe_metric(fn -> :erlang.memory(:total) end)
    }
  end

  defp safe_metric(fun) do
    case fun.() do
      value when is_integer(value) and value >= 0 -> value
      _ -> :unavailable
    end
  rescue
    _ -> :unavailable
  catch
    _, _ -> :unavailable
  end

  defp metric_observation(before, after_value) do
    Map.new(before, fn {key, initial} ->
      terminal = Map.fetch!(after_value, key)

      delta =
        if is_integer(initial) and is_integer(terminal),
          do: terminal - initial,
          else: :unavailable

      {key, %{before: initial, after: terminal, delta: delta}}
    end)
  end

  defp failed(state, started) do
    %{
      state
      | recovery: %{
          state.recovery
          | cleanup: %{
              status: :failed,
              elapsed_ms: now() - started,
              exceeded_deadline: now() - started > @deadline_ms,
              unresolved: 1,
              failed: 1,
              timed_out: 0,
              forced: 0,
              callback_failures: 1,
              requested: 0,
              pages: [],
              amplification: amplification(empty_stats(), empty_stats(), 0, 0),
              runtime_metrics: %{instrumentation: :unavailable},
              stage_timings_ms: %{total: now() - started}
            }
        }
    }
  end
end
