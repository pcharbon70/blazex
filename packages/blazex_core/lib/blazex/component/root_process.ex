defmodule BlazeX.Component.RootProcess do
  @moduledoc false
  use GenServer

  alias BlazeX.Component.{
    ActionRuntime,
    RootPort,
    RootSchedule,
    RootTimers,
    SchedulingIntents,
    ScopedView
  }

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({:recovery_crash, state}) do
    Process.flag(:trap_exit, true)
    send(self(), :recover_crash)
    {:ok, state}
  end

  def init({guardian, spec, ports, policy, actions, recovery}) do
    Process.flag(:trap_exit, true)
    {:ok, state} = init({guardian, spec, ports, policy, actions})
    state = %{state | recovery: recovery, attempt: recovery.sequence}
    send(guardian, {:recovery_checkpoint, self(), state})
    {:ok, state}
  end

  def init({guardian, spec, ports}), do: init({guardian, spec, ports, nil})

  def init({guardian, spec, ports, policy}), do: init({guardian, spec, ports, policy, nil})

  def init({guardian, spec, ports, policy, actions}) do
    {:ok, schedule} = RootSchedule.new(policy)
    {:ok, actions} = ActionRuntime.new(actions)
    send(self(), :boot)

    {:ok,
     %{
       guardian: guardian,
       spec: spec,
       ports: ports,
       accepted: nil,
       pending: nil,
       status: :starting,
       attempt: 0,
       error: nil,
       schedule: schedule,
       active_correlation: nil,
       timers: %RootTimers{},
       candidate_intents: [],
       actions: actions,
       action_plan: nil,
       scope_intents: [],
       recovery: nil
     }}
  end

  @impl true
  def handle_info(:recover_crash, state) do
    {_, next} = BlazeX.Component.RecoveryRuntime.fail(state, :crashed)
    info_result(next)
  end

  def handle_info(:boot, state) do
    notify(state, :registered)
    {_reply, next} = begin(state, state.spec, :mount)
    info_result(settle(next))
  end

  def handle_info({:deadline, correlation}, %{pending: %{correlation: correlation}} = state) do
    {_reply, next} = abandon(state, :timeout)
    info_result(settle(next))
  end

  def handle_info(:drain, %{schedule: schedule, status: :ready, pending: nil} = state)
      when schedule != nil,
      do: info_result(run_next(state))

  def handle_info(:drain, state), do: {:noreply, state}

  def handle_info({:action_timeout, correlation, token}, %{actions: actions} = state)
      when actions != nil do
    case ActionRuntime.timeout(actions, correlation, token, state.accepted) do
      {:ok, actions, item} -> info_result(settle(action_result_ready(state, actions, [item])))
      _ -> {:noreply, state}
    end
  end

  def handle_info({:owned_tick, key, epoch, token}, %{schedule: schedule} = state)
      when schedule != nil do
    next =
      case RootTimers.wake(state.timers, key, epoch, token, state.accepted) do
        {:ok, item, timers} ->
          case RootSchedule.internal(schedule, item) do
            {:ok, _item, next_schedule} ->
              %{state | timers: timers, schedule: next_schedule}

            {:error, _} ->
              next = %{
                state
                | timers: RootTimers.finish(timers, item),
                  schedule: RootSchedule.reject(schedule)
              }

              notify(next, :timer_overload)
              next
          end

        {:error, timers} ->
          next = %{state | timers: timers}
          notify(next, :timer_rejected)
          next
      end

    info_result(settle(next))
  end

  def handle_info(_, %{schedule: nil} = state), do: {:noreply, state}

  def handle_info(_, state) do
    next = %{state | schedule: RootSchedule.reject(state.schedule)}
    notify(next, :unknown_mailbox)
    {:noreply, next}
  end

  @impl true
  def handle_call(operation, _from, state) do
    {reply, next} = dispatch(operation, state)
    next = settle(next)
    checkpoint(next)

    if next.status in [:disposed, :failed],
      do: {:stop, :normal, {reply, snapshot(next)}, next},
      else: {:reply, {reply, snapshot(next)}, next}
  end

  @impl true
  def format_status(status),
    do:
      Map.new(status, fn {key, _} ->
        {key, if(key == :log, do: [], else: :redacted_root_coordinator)}
      end)

  defp info_result(state) do
    checkpoint(state)
    if state.status in [:disposed, :failed], do: {:stop, :normal, state}, else: {:noreply, state}
  end

  defp dispatch(:snapshot, state), do: {{:ok, snapshot(state)}, state}
  defp dispatch({:ack, acknowledgement}, state), do: acknowledge(state, acknowledgement)

  defp dispatch({:action_result, result}, %{actions: actions, status: status} = state)
       when actions != nil and status in [:ready, :awaiting_commit] do
    case ActionRuntime.complete(actions, result, state.accepted) do
      {:ok, actions, item} -> {:ok, action_result_ready(state, actions, [item])}
      _ -> {{:error, :invalid_or_stale_result}, state}
    end
  end

  defp dispatch({:action_result, _}, state), do: {{:error, :invalid_or_stale_result}, state}

  defp dispatch(
         {:enqueue, %{scope_version: _} = payload},
         %{schedule: schedule, status: status} = state
       )
       when schedule != nil and status in [:ready, :awaiting_commit] and state.accepted != nil do
    with work when is_map(work) <-
           RootPort.call(state.ports.evaluator, :scope_ingress, [payload, state.accepted]),
         true <- ScopedView.valid_work?(work, state.accepted),
         {:ok, item, schedule} <- RootSchedule.internal(schedule, work) do
      {{:ok, %{receipt: item.receipt}}, %{state | schedule: schedule}}
    else
      _ -> {{:error, :invalid_scope_change}, state}
    end
  end

  defp dispatch({:enqueue, envelope}, %{schedule: schedule, status: status} = state)
       when schedule != nil and status in [:ready, :awaiting_commit] and state.accepted != nil do
    case RootSchedule.admit(schedule, envelope, state.accepted, state.spec) do
      {:ok, item, superseded, next_schedule} ->
        if RootPort.call(state.ports.evaluator, :admit, [item, state.accepted]) == :ok do
          next = %{state | schedule: next_schedule}
          if superseded, do: outcome(next, superseded, :coalesced, nil)
          next = if item.kind == :timer_cancel, do: cancel_owned(next, item), else: next
          notify(next, :admitted)
          send(self(), :drain)
          {{:ok, %{receipt: item.receipt, sequence: item.sequence}}, next}
        else
          {{:error, :invalid_ingress}, %{state | schedule: RootSchedule.reject(schedule)}}
        end

      {:error, code, next_schedule} ->
        {{:error, code}, %{state | schedule: next_schedule}}
    end
  end

  defp dispatch({:enqueue, _}, state), do: {{:error, :invalid_ingress}, state}

  defp dispatch({:stop, reason}, %{recovery: recovery} = state)
       when recovery != nil and reason in [:shutdown, :removal],
       do: BlazeX.Component.RecoveryRuntime.stop(state, reason)

  defp dispatch({:replace, revision, spec}, %{recovery: recovery, accepted: accepted} = state)
       when recovery != nil and accepted != nil do
    with true <- revision == accepted.correlation.revision,
         {:ok, spec} <- RootPort.normalize(spec),
         true <- RootPort.handle(spec) == RootPort.handle(state.spec) do
      next = BlazeX.Component.RecoveryCleanup.run(state, :replace)

      if next.recovery.cleanup.unresolved == 0 and next.recovery.cleanup.callback_failures == 0 do
        next = %{
          next
          | recovery: %{next.recovery | generation: accepted.correlation.generation + 1}
        }

        begin(next, spec, :replace)
      else
        BlazeX.Component.RecoveryRuntime.fail(%{next | accepted: nil}, :cleanup_failed)
      end
    else
      _ -> {{:error, :stale}, state}
    end
  end

  defp dispatch({:stop, reason}, state) when reason in [:shutdown, :removal],
    do: stopping(state, reason)

  defp dispatch(:runtime_loss, %{recovery: recovery} = state) when recovery != nil,
    do: BlazeX.Component.RecoveryRuntime.fail(state, :runtime_loss)

  defp dispatch(:runtime_loss, %{schedule: schedule} = state) when schedule != nil do
    state = close_schedule(state, :runtime_loss)
    cancel_timer(state)

    if state.pending,
      do: RootPort.call(state.ports.renderer, :cancel, [state.pending.correlation])

    failed(state, :runtime_loss)
  end

  defp dispatch({:replace, revision, spec}, %{schedule: schedule, accepted: accepted} = state)
       when schedule != nil and accepted != nil do
    with true <- revision == accepted.correlation.revision,
         {:ok, spec} <- RootPort.normalize(spec),
         true <- RootPort.handle(spec) == RootPort.handle(state.spec) do
      next = close_schedule(state, :replace)
      cancel_timer(next)

      cancelled =
        if next.pending,
          do: RootPort.call(next.ports.renderer, :cancel, [next.pending.correlation]),
          else: :ok

      if cancelled == :ok,
        do: begin(%{next | pending: nil}, spec, :replace),
        else: failed(next, :rollback_failed)
    else
      _ -> {{:error, :stale}, state}
    end
  end

  defp dispatch(_operation, %{status: status} = state) when status != :ready,
    do: {{:error, :busy}, state}

  defp dispatch({:update, _, _, _}, %{schedule: schedule} = state) when schedule != nil,
    do: {{:error, :scheduled_ingress_required}, state}

  defp dispatch({:update, revision, props, slots}, state) do
    if revision == state.accepted.correlation.revision,
      do: normalized_begin(state, %{state.spec | props: props, slots: slots}, :update),
      else: {{:error, :stale}, state}
  end

  defp dispatch({:replace, revision, spec}, state) do
    if revision == state.accepted.correlation.revision and is_map(spec) and
         RootPort.handle(spec) == RootPort.handle(state.spec),
       do: normalized_begin(state, spec, :replace),
       else: {{:error, :stale}, state}
  end

  defp dispatch(_, state), do: {{:error, :invalid_request}, state}

  defp normalized_begin(state, spec, operation) do
    case RootPort.normalize(spec) do
      {:ok, normalized} -> begin(state, normalized, operation)
      _ -> {{:error, :invalid_request}, state}
    end
  end

  defp begin(state, spec, operation, work \\ nil) do
    old =
      if state.accepted,
        do: state.accepted.correlation,
        else: %{
          generation: if(state.recovery, do: state.recovery.generation, else: 1),
          revision: 0
        }

    generation = old.generation + if(operation == :replace, do: 1, else: 0)
    revision = if operation == :replace, do: 1, else: old.revision + 1

    case RootPort.correlation(spec, generation, revision, state.attempt + 1, operation) do
      {:ok, correlation} ->
        state =
          if state.recovery,
            do: %{state | recovery: %{state.recovery | correlation: correlation}},
            else: state

        state = %{state | status: phase(operation), attempt: correlation.sequence, error: nil}
        notify(state, :evaluating)
        request = %{spec: spec, operation: operation, correlation: correlation}
        request = if work, do: Map.put(request, :work, work), else: request
        state = %{state | status: :evaluating}
        state = if work, do: %{state | active_correlation: correlation}, else: state
        callback = if work, do: :prepare_scheduled, else: :prepare

        case RootPort.call(state.ports.evaluator, callback, [request, state.accepted]) do
          {:ok, candidate, groups} when work != nil ->
            with true <- RootPort.candidate?(candidate, correlation),
                 {:ok, intents, reservations, action_plan} <-
                   candidate_actions(state, groups, candidate, spec),
                 true <-
                   Enum.all?(
                     intents,
                     &(RootPort.call(state.ports.evaluator, :admit, [&1, candidate]) == :ok)
                   ),
                 :ok <- RootTimers.preflight(state.timers, intents),
                 {:ok, scope_intents} <- ScopedView.followups(state.ports.evaluator, candidate),
                 {:ok, schedule} <-
                   RootSchedule.reserve(
                     state.schedule,
                     reservations ++ scope_intents
                   ) do
              submit(
                %{
                  state
                  | schedule: schedule,
                    candidate_intents: intents,
                    action_plan: action_plan,
                    scope_intents: scope_intents
                },
                spec,
                correlation,
                candidate,
                nil
              )
            else
              _ -> rejected(state, :semantic_rejected)
            end

          {:ok, candidate} ->
            if RootPort.candidate?(candidate, correlation),
              do: submit(state, spec, correlation, candidate, nil),
              else: rejected(state, :semantic_rejected)

          _ ->
            rejected(state, :semantic_rejected)
        end

      _ ->
        {{:error, :invalid_request}, state}
    end
  end

  defp submit(state, spec, correlation, candidate, reason) do
    pending = %{
      correlation: correlation,
      candidate: candidate,
      spec: spec,
      reason: reason,
      timer: nil
    }

    state = %{state | pending: pending, status: if(reason, do: :stopping, else: :awaiting_commit)}

    case RootPort.call(state.ports.renderer, :submit, [correlation, candidate]) do
      :ok ->
        timer = Process.send_after(self(), {:deadline, correlation}, spec.timeout_ms)
        next = %{state | pending: %{pending | timer: timer}}
        notify(next, :pending)
        {{:ok, correlation}, next}

      _ ->
        abandon(state, :renderer_rejected)
    end
  end

  defp acknowledge(%{pending: nil} = state, _), do: {{:error, :stale}, state}

  defp acknowledge(state, acknowledgement) do
    if RootPort.acknowledgement?(acknowledgement, state.pending.correlation) do
      cancel_timer(state)

      case acknowledgement.result do
        :committed -> committed(state)
        _ -> rejected(state, :renderer_rejected)
      end
    else
      {{:error, :stale}, state}
    end
  end

  defp committed(%{recovery: recovery, pending: %{correlation: %{operation: :failure}}} = state)
       when recovery != nil,
       do: BlazeX.Component.RecoveryRuntime.fallback_committed(state)

  defp committed(%{pending: %{reason: reason}} = state) when reason != nil do
    result = cleanup(state, state.accepted, reason)

    if result == :ok do
      next = %{state | pending: nil, status: :disposed, error: nil}
      notify(next, :disposed)
      {:ok, next}
    else
      failed(state, :cleanup_failed)
    end
  end

  defp committed(state) do
    pending = state.pending

    next = %{
      state
      | accepted: pending.candidate,
        pending: nil,
        spec: pending.spec,
        status: :ready,
        error: nil
    }

    {next, cleanup_result} =
      if state.recovery != nil and state.accepted != nil and
           pending.correlation.operation != :replace do
        cleaned =
          BlazeX.Component.RecoveryCleanup.run(
            %{state | pending: nil},
            :removal,
            pending.candidate
          )

        next = %{next | recovery: cleaned.recovery, actions: cleaned.actions}

        {next,
         if(
           cleaned.recovery.cleanup.unresolved == 0 and cleaned.recovery.cleanup.failed == 0 and
             cleaned.recovery.cleanup.timed_out == 0,
           do: :ok,
           else: {:error, :cleanup_failed}
         )}
      else
        result =
          cond do
            pending.correlation.operation == :replace and state.recovery != nil ->
              :ok

            pending.correlation.operation == :replace ->
              cleanup(state, state.accepted, :replace)

            state.schedule != nil and state.accepted != nil ->
              RootPort.call(state.ports.evaluator, :cleanup_removed, [
                state.accepted,
                pending.candidate
              ])

            true ->
              :ok
          end

        {next, result}
      end

    if cleanup_result == :ok do
      notify(next, :ready)
      {:ok, next}
    else
      failed(next, :cleanup_failed)
    end
  end

  defp stopping(%{status: :stopping} = state, _), do: {{:ok, state.pending.correlation}, state}

  defp stopping(state, reason) do
    state = close_schedule(state, reason)
    cancel_timer(state)

    cancelled =
      if state.pending,
        do: RootPort.call(state.ports.renderer, :cancel, [state.pending.correlation]),
        else: :ok

    if cancelled == :ok do
      old = if state.accepted, do: state.accepted.correlation, else: %{generation: 1, revision: 1}

      case RootPort.correlation(
             state.spec,
             old.generation,
             old.revision,
             state.attempt + 1,
             :dispose
           ) do
        {:ok, correlation} ->
          next = %{state | pending: nil, status: :stopping, attempt: correlation.sequence}
          notify(next, reason)
          submit(next, state.spec, correlation, nil, reason)

        _ ->
          failed(state, :invalid_request)
      end
    else
      failed(state, :rollback_failed)
    end
  end

  defp abandon(state, code) do
    cancel_timer(state)

    if RootPort.call(state.ports.renderer, :cancel, [state.pending.correlation]) == :ok,
      do: rejected(state, code),
      else: failed(state, :rollback_failed)
  end

  defp rejected(%{recovery: recovery} = state, code) when recovery != nil,
    do: BlazeX.Component.RecoveryRuntime.fail(state, code)

  defp rejected(state, code) do
    if state.accepted == nil or state.status == :stopping do
      failed(state, code)
    else
      next = %{state | pending: nil, status: :ready, error: RootPort.failure(code)}
      notify(next, :rejected)
      {{:error, RootPort.failure(code)}, next}
    end
  end

  defp failed(%{recovery: recovery} = state, code) when recovery != nil,
    do: BlazeX.Component.RecoveryRuntime.fail(state, code)

  defp failed(state, code) do
    next = %{state | pending: nil, status: :failed, error: RootPort.failure(code)}
    notify(next, :failed)
    {{:error, RootPort.failure(code)}, next}
  end

  defp cleanup(_state, nil, _reason), do: :ok

  defp cleanup(state, accepted, reason),
    do: RootPort.call(state.ports.evaluator, :cleanup, [accepted, reason])

  defp cancel_timer(%{pending: %{timer: timer}}) when timer != nil,
    do: Process.cancel_timer(timer)

  defp cancel_timer(_), do: :ok
  defp phase(:mount), do: :mounting
  defp phase(:update), do: :updating
  defp phase(:replace), do: :replacing

  defp snapshot(state) do
    value = %{
      contract: RootPort.version(),
      handle: RootPort.handle(state.spec),
      status: state.status,
      accepted: RootPort.summary(state.accepted),
      pending: if(state.pending, do: state.pending.correlation, else: nil),
      attempt: state.attempt,
      error: state.error
    }

    value =
      if state.recovery,
        do:
          Map.put(
            value,
            :recovery,
            Map.take(state.recovery, [:generation, :retry_count, :failure, :cleanup])
          ),
        else: value

    value =
      if state.actions,
        do: Map.put(value, :actions, ActionRuntime.snapshot(state.actions)),
        else: value

    if state.schedule,
      do:
        value
        |> Map.put(:scheduling, RootSchedule.metrics(state.schedule))
        |> Map.put(:timers, RootTimers.inventory(state.timers)),
      else: value
  end

  defp run_next(state) do
    case RootSchedule.select(state.schedule) do
      {:ok, work, schedule} ->
        next = %{state | schedule: schedule}

        if RootSchedule.valid_dispatch?(work, state.accepted) and
             RootTimers.valid_tick?(state.timers, work) and
             RootPort.call(state.ports.evaluator, :admit, [work, state.accepted]) == :ok do
          if work.kind in [:timer_start, :timer_cancel] do
            timer_control(next, work)
          else
            spec =
              if work.kind == :update, do: Map.merge(state.spec, work.payload), else: state.spec

            {_reply, next} = begin(next, spec, :update, work)
            settle(next)
          end
        else
          outcome(next, work, :rejected, :stale_target)
          send(self(), :drain)

          %{
            next
            | schedule: RootSchedule.finish(schedule),
              timers: RootTimers.finish(next.timers, work)
          }
        end

      {:empty, _} ->
        state
    end
  end

  defp settle(%{schedule: nil} = state), do: state

  defp settle(state) do
    state =
      if state.pending == nil and state.schedule.active != nil do
        committed =
          state.accepted != nil and state.accepted.correlation == state.active_correlation

        outcome(
          state,
          state.schedule.active,
          if(committed, do: :committed, else: :rejected),
          state.error
        )

        next = %{
          state
          | schedule: RootSchedule.finish(state.schedule),
            active_correlation: nil,
            actions: ActionRuntime.finish_result(state.actions, state.schedule.active, committed),
            timers: RootTimers.finish(state.timers, state.schedule.active)
        }

        next =
          if committed and state.status == :ready,
            do: apply_intents(next, state.candidate_intents),
            else: next

        next =
          if committed and state.status == :ready and state.action_plan != nil do
            {actions, work} =
              ActionRuntime.commit(next.actions, state.action_plan, state.accepted, fn actions ->
                send(state.guardian, {:root_actions, self(), actions})
              end)

            action_result_ready(next, actions, work)
          else
            next
          end

        next =
          if committed and state.status == :ready do
            Enum.reduce(state.scope_intents, next, fn work, acc ->
              {:ok, _, schedule} = RootSchedule.internal(acc.schedule, work)
              %{acc | schedule: schedule}
            end)
          else
            next
          end

        %{next | candidate_intents: [], action_plan: nil, scope_intents: []}
      else
        state
      end

    state =
      if state.accepted != nil do
        timers = RootTimers.prune(state.timers, state.accepted)

        {removed, schedule} =
          RootSchedule.drop(
            state.schedule,
            &(not RootSchedule.valid_dispatch?(&1, state.accepted) or
                not RootTimers.valid_tick?(timers, &1))
          )

        Enum.each(removed, &outcome(state, &1, :canceled, :removed_target))
        actions = Enum.reduce(removed, state.actions, &ActionRuntime.finish_result(&2, &1, false))
        %{state | timers: timers, schedule: schedule, actions: actions}
      else
        state
      end

    state =
      if state.actions != nil and state.accepted != nil do
        actions = ActionRuntime.prune(state.actions, state.accepted)
        {:ok, schedule} = RootSchedule.results(state.schedule, ActionRuntime.pending(actions))
        %{state | actions: actions, schedule: schedule}
      else
        state
      end

    cond do
      state.status in [:failed, :disposed] ->
        close_schedule(state, state.status)

      state.status == :ready and state.pending == nil and state.schedule.queue != [] ->
        send(self(), :drain)
        state

      true ->
        state
    end
  end

  defp close_schedule(%{schedule: nil} = state, _), do: state

  defp close_schedule(state, reason) do
    work =
      state.schedule.queue ++ if(state.schedule.active, do: [state.schedule.active], else: [])

    Enum.each(work, &outcome(state, &1, :canceled, reason))

    %{
      state
      | schedule: %{RootSchedule.finish(state.schedule) | queue: [], result_slots: 0},
        active_correlation: nil,
        candidate_intents: [],
        timers: RootTimers.cancel_all(state.timers),
        actions: ActionRuntime.close(state.actions, reason),
        action_plan: nil,
        scope_intents: []
    }
  end

  defp timer_control(state, work) do
    result =
      case work.kind do
        :timer_start -> RootTimers.install(state.timers, work)
        :timer_cancel -> {:ok, RootTimers.cancel(state.timers, RootTimers.key(work))}
      end

    {result, reason, timers} =
      case result do
        {:ok, timers} -> {:committed, nil, timers}
        {:error, reason} -> {:rejected, reason, state.timers}
      end

    outcome(state, work, result, reason)
    settle(%{state | timers: timers, schedule: RootSchedule.finish(state.schedule)})
  end

  defp cancel_owned(state, item) do
    key = RootTimers.key(item)

    {removed, schedule} =
      RootSchedule.drop(
        state.schedule,
        &(&1.kind in [:timer_start, :timer_tick] and RootTimers.key(&1) == key)
      )

    Enum.each(removed, &outcome(state, &1, :canceled, :timer_cancel))

    intents =
      Enum.reject(
        state.candidate_intents,
        &(&1.kind == :timer_start and RootTimers.key(&1) == key)
      )

    state = %{
      state
      | timers: RootTimers.cancel(state.timers, key),
        schedule: schedule,
        candidate_intents: intents
    }

    active = state.schedule.active

    state =
      if active != nil and active.kind == :timer_tick and RootTimers.key(active) == key do
        outcome(state, active, :canceled, :timer_cancel)

        next = %{
          state
          | schedule: RootSchedule.finish(state.schedule),
            active_correlation: nil,
            candidate_intents: [],
            action_plan: nil,
            scope_intents: []
        }

        if next.pending do
          {_reply, next} = abandon(next, :timer_canceled)
          next
        else
          next
        end
      else
        state
      end

    outcome(state, item, :committed, nil)
    state
  end

  defp apply_intents(state, intents) do
    Enum.reduce(intents, state, fn item, acc ->
      case item.kind do
        :message ->
          {:ok, schedule, _items} = RootSchedule.followups(acc.schedule, [item])
          %{acc | schedule: schedule}

        :timer_start ->
          {:ok, timers} = RootTimers.install(acc.timers, item)
          %{acc | timers: timers}

        :timer_cancel ->
          %{acc | timers: RootTimers.cancel(acc.timers, RootTimers.key(item))}
      end
    end)
  end

  defp outcome(state, item, result, reason) do
    record =
      Map.merge(snapshot(state), %{
        event: :work_outcome,
        work: Map.take(item, [:receipt, :class, :producer, :sequence]),
        result: result,
        reason: reason,
        correlation: work_correlation(state, item)
      })

    send(state.guardian, {:root_work_done, self(), item.receipt})
    RootPort.call(state.ports.host, :notify, [record])
  end

  defp notify(state, event) do
    checkpoint(state)
    snapshot = snapshot(state)
    send(state.guardian, {:root_snapshot, self(), snapshot})
    RootPort.call(state.ports.host, :notify, [Map.put(snapshot, :event, event)])
    :ok
  end

  defp checkpoint(state) do
    if state.recovery, do: send(state.guardian, {:recovery_checkpoint, self(), state})
    checkpoint_work(state)
  end

  defp checkpoint_work(%{schedule: nil}), do: :ok

  defp checkpoint_work(state) do
    if state.actions != nil, do: send(state.guardian, {:root_actions, self(), state.actions})

    work =
      state.schedule.queue ++ if(state.schedule.active, do: [state.schedule.active], else: [])

    work =
      Enum.map(
        work,
        &(Map.take(&1, [:receipt, :class, :producer, :sequence])
          |> Map.put(:correlation, work_correlation(state, &1)))
      )

    send(state.guardian, {:root_work, self(), work, RootTimers.refs(state.timers)})
    :ok
  end

  defp work_correlation(state, item) do
    if state.schedule.active != nil and state.schedule.active.receipt == item.receipt,
      do: state.active_correlation,
      else: nil
  end

  defp candidate_actions(%{actions: nil} = state, groups, candidate, spec) do
    with {:ok, intents} <-
           SchedulingIntents.normalize(state.schedule.policy, groups, candidate, spec) do
      {:ok, intents, Enum.filter(intents, &(&1.kind == :message)), nil}
    end
  end

  defp candidate_actions(state, groups, candidate, spec) do
    with {:ok, plan} <-
           ActionRuntime.prepare(
             state.actions,
             groups,
             candidate,
             spec,
             state.schedule.policy,
             state.ports.evaluator
           ) do
      {:ok, plan.local, plan.reservations, plan}
    end
  end

  defp action_result_ready(state, actions, work) do
    send(state.guardian, {:root_actions, self(), actions})
    {:ok, schedule} = RootSchedule.results(state.schedule, ActionRuntime.pending(actions))

    schedule =
      Enum.reduce(work, schedule, fn item, acc ->
        {:ok, _item, next} = RootSchedule.internal(acc, item)
        next
      end)

    %{state | actions: actions, schedule: schedule}
  end

  def recovery_submit(state, correlation, candidate),
    do: submit(state, state.spec, correlation, candidate, nil)

  def recovery_close(state, _reason) do
    if state.schedule do
      %{
        state
        | schedule: %{RootSchedule.finish(state.schedule) | queue: [], result_slots: 0},
          active_correlation: nil,
          candidate_intents: [],
          scope_intents: [],
          action_plan: nil,
          timers: RootTimers.cancel_all(state.timers)
      }
    else
      state
    end
  end

  def recovery_notify(state, event), do: notify(state, event)
  def recovery_snapshot(state), do: snapshot(state)
end
