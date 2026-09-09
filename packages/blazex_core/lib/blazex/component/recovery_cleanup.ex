defmodule BlazeX.Component.RecoveryCleanup do
  @moduledoc "Deadline-bound owner cleanup; failed release is never silently counted as success."
  alias BlazeX.Component.{ActionLedger, RecoveryPort, RootProcess}

  def run(state, reason, next \\ nil), do: execute_root(state, reason, next, now())

  defp execute_root(state, reason, next, started) do
    deadline = started + 1000

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
    {rows, _} = execute(pending ++ cancellations, [], deadline)

    owners =
      if state.accepted &&
           state.recovery.cleaned_generation != state.accepted.correlation.generation,
         do: bounded(state.ports.evaluator, :cleanup_owners, [state.accepted], deadline),
         else: []

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

    {rows, _} = execute(component_jobs, rows, deadline)
    leases = if actions, do: Enum.sort_by(Map.values(actions.ledger.leases), & &1.id), else: []
    leases = Enum.filter(leases, &selected.(&1.owner))

    lease_jobs =
      Enum.map(
        leases,
        &job(&1.owner, :lease, actions.port, :release, %{&1 | release_requested: true})
      )

    request = %{root: owner.root, generation: generation, reason: reason, restore_focus: true}

    {rows, _} =
      execute(
        lease_jobs ++
          if(next, do: [], else: [job(owner, :renderer, state.ports.renderer, :dispose, request)]),
        rows,
        deadline
      )

    elapsed = now() - started
    unresolved = Enum.count(rows, & &1.unresolved)

    report = %{
      status: if(unresolved == 0, do: :completed, else: :failed),
      elapsed_ms: elapsed,
      exceeded_deadline: elapsed > 1000,
      unresolved: unresolved,
      failed: Enum.count(rows, &(&1.status == :failed)),
      timed_out: Enum.count(rows, &(&1.status == :timed_out)),
      forced: Enum.count(rows, &(&1.force_status == :completed)),
      requested: length(rows),
      pages: Enum.chunk_every(rows, 128)
    }

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
  rescue
    _ ->
      %{
        state
        | recovery: %{
            state.recovery
            | cleanup: %{
                status: :failed,
                elapsed_ms: now() - started,
                exceeded_deadline: now() - started > 1000,
                unresolved: 1,
                failed: 1,
                timed_out: 0,
                forced: 0,
                requested: 0,
                pages: []
              }
          }
      }
  catch
    _, _ ->
      %{
        state
        | recovery: %{
            state.recovery
            | cleanup: %{
                status: :failed,
                elapsed_ms: now() - started,
                exceeded_deadline: now() - started > 1000,
                unresolved: 1,
                failed: 1,
                timed_out: 0,
                forced: 0,
                requested: 0,
                pages: []
              }
          }
      }
  end

  defp execute(jobs, rows, deadline) do
    Enum.reduce(jobs, {rows, deadline}, fn job, {rows, deadline} ->
      started = now()
      result = bounded(job.port, job.callback, job.arguments, deadline)
      status = status(result)

      force =
        if status != :completed and job.kind != :component,
          do:
            status(
              bounded(
                job.port,
                :force_cleanup,
                [%{kind: job.kind, owner: job.owner, reference: job.reference}],
                deadline
              )
            ),
          else: :not_requested

      unresolved = job.kind != :component and status != :completed and force != :completed
      reference = if job.kind == :lease, do: ActionLedger.lease_ref(job.reference), else: nil

      row = %{
        owner: job.owner,
        kind: job.kind,
        reference: reference,
        requested: true,
        status: status,
        force_status: force,
        elapsed_ms: now() - started,
        unresolved: unresolved
      }

      {rows ++ [row], deadline}
    end)
  end

  defp job(owner, kind, port, callback, reference),
    do: %{
      owner: owner,
      kind: kind,
      port: port,
      callback: callback,
      arguments: [reference],
      reference: reference
    }

  defp bounded({RecoveryPort, {port, _}}, callback, args, deadline),
    do: bounded(port, callback, args, deadline)

  defp bounded(port, callback, args, deadline),
    do: RecoveryPort.call(port, callback, args, min(100, deadline - now()))

  defp status(result) when result in [:ok, :released], do: :completed
  defp status({:error, :timed_out}), do: :timed_out
  defp status(_), do: :failed
  defp now, do: System.monotonic_time(:millisecond)
end
