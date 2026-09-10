defmodule BlazeX.Component.RecoveryCleanup do
  @moduledoc "Deadline-bound owner cleanup; failed release is never silently counted as success."
  alias BlazeX.Component.{ActionLedger, RecoveryPort, RootProcess}

  @deadline_ms 1000

  def run(state, reason, next \\ nil), do: execute_root(state, reason, next, now())

  defp execute_root(state, reason, next, started) do
    deadline = started + @deadline_ms
    {:ok, session} = RecoveryPort.open_session()

    try do
      execute_root_with_session(state, reason, next, started, deadline, session)
    after
      RecoveryPort.close_session(session)
    end
  rescue
    _ -> failed(state, started)
  catch
    _, _ -> failed(state, started)
  end

  defp execute_root_with_session(state, reason, next, started, deadline, session) do
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
    {rows, session} = execute(pending ++ cancellations, [], deadline, session)

    {owners, session} =
      if state.accepted &&
           state.recovery.cleaned_generation != state.accepted.correlation.generation,
         do: invoke(session, state.ports.evaluator, :cleanup_owners, [state.accepted], deadline),
         else: {[], session}

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

    {rows, session} = execute(component_jobs, rows, deadline, session)
    leases = if actions, do: Enum.sort_by(Map.values(actions.ledger.leases), & &1.id), else: []
    leases = Enum.filter(leases, &selected.(&1.owner))

    lease_jobs =
      Enum.map(
        leases,
        &job(&1.owner, :lease, actions.port, :release, %{&1 | release_requested: true})
      )

    lease_pages_before = session.pages_sent
    {rows, session} = execute(lease_jobs, rows, deadline, session)
    lease_pages_sent = session.pages_sent - lease_pages_before

    request = %{root: owner.root, generation: generation, reason: reason, restore_focus: true}

    {rows, session} =
      execute(
        if(next, do: [], else: [job(owner, :renderer, state.ports.renderer, :dispose, request)]),
        rows,
        deadline,
        session
      )

    rows = Enum.reverse(rows)
    normal_stats = RecoveryPort.session_stats(session)
    RecoveryPort.close_session(session)
    {rows, forced_stats, forced_worker_starts} = force(rows, deadline)
    rows = Enum.map(rows, &Map.drop(&1, [:port, :force_reference]))
    elapsed = now() - started
    prior = state.recovery.cleanup
    prior_unresolved = if prior, do: prior.unresolved, else: 0
    unresolved = max(Enum.count(rows, & &1.unresolved), prior_unresolved)

    report = %{
      status: if(unresolved == 0, do: :completed, else: :failed),
      elapsed_ms: elapsed,
      exceeded_deadline: elapsed > @deadline_ms,
      unresolved: unresolved,
      failed: Enum.count(rows, &(&1.status == :failed)),
      timed_out: Enum.count(rows, &(&1.status == :timed_out)),
      forced: Enum.count(rows, &(&1.force_status == :completed)),
      callback_failures: Enum.count(rows, &(&1.kind == :component and &1.status != :completed)),
      requested: length(rows),
      pages: Enum.chunk_every(rows, 128),
      amplification:
        amplification(normal_stats, forced_stats, forced_worker_starts, lease_pages_sent)
    }

    # A later empty ledger cannot prove release of an earlier lost resource.
    # Retain the first unresolved inventory without recursively growing reports.
    report =
      if prior_unresolved > 0,
        do: Map.put(report, :unresolved_pages, Map.get(prior, :unresolved_pages, prior.pages)),
        else: report

    actions =
      if actions do
        ledger =
          Enum.reduce(requests, actions.ledger, fn entry, acc ->
            ActionLedger.record(acc, :canceled, entry.correlation)
          end)

        ledger =
          Enum.reduce(leases, ledger, fn lease, acc ->
            row =
              Enum.find(
                rows,
                &(&1.kind == :lease and &1.reference == ActionLedger.lease_ref(lease))
              )

            ActionLedger.released(acc, lease, if(row.unresolved, do: :lost, else: :released))
          end)

        pending = Map.drop(ledger.pending, canceled)
        timers = if next, do: Map.drop(actions.timers, canceled), else: %{}
        %{actions | ledger: %{ledger | pending: pending}, timers: timers}
      else
        nil
      end

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

        [
          %{
            owner: job.owner,
            kind: job.kind,
            reference: reference,
            force_reference: job.reference,
            port: job.port,
            requested: true,
            status: status(result),
            force_status: :not_requested,
            elapsed_ms: elapsed,
            unresolved: false
          }
          | acc
        ]
      end)

    {next, session}
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

  defp force(rows, deadline) do
    candidates =
      rows
      |> Enum.with_index()
      |> Enum.filter(fn {row, _} -> row.kind != :component and row.status != :completed end)

    cond do
      candidates == [] ->
        {Enum.map(rows, &Map.put(&1, :unresolved, false)), empty_stats(), 0}

      deadline - now() <= 0 ->
        indexes = Map.new(candidates, fn {_, index} -> {index, :timed_out} end)
        {apply_force(rows, indexes), empty_stats(), 0}

      true ->
        {:ok, session} = RecoveryPort.open_session()

        jobs =
          Enum.map(candidates, fn {row, index} ->
            %{
              owner: row.owner,
              kind: :force,
              port: row.port,
              callback: :force_cleanup,
              arguments: [
                %{kind: row.kind, owner: row.owner, reference: row.force_reference}
              ],
              reference: index
            }
          end)

        try do
          {records, updated} = call_jobs(jobs, deadline, session)
          stats = RecoveryPort.session_stats(updated)
          indexes = Map.new(records, fn {job, result, _} -> {job.reference, status(result)} end)
          {apply_force(rows, indexes), stats, 1}
        after
          RecoveryPort.close_session(session)
        end
    end
  end

  defp apply_force(rows, indexes) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} ->
      force_status = Map.get(indexes, index, :not_requested)

      %{
        row
        | force_status: force_status,
          unresolved:
            row.kind != :component and row.status != :completed and force_status != :completed
      }
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
      messages_received: 0
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
              amplification: amplification(empty_stats(), empty_stats(), 0, 0)
            }
        }
    }
  end
end
