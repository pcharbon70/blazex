defmodule BlazeX.Component.RootProcess do
  @moduledoc false
  use GenServer
  alias BlazeX.Component.{RootPort, RootSchedule}

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({guardian, spec, ports}), do: init({guardian, spec, ports, nil})

  def init({guardian, spec, ports, policy}) do
    {:ok, schedule} = RootSchedule.new(policy)
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
       active_correlation: nil
     }}
  end

  @impl true
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
  def handle_info(_, %{schedule: nil} = state), do: {:noreply, state}

  def handle_info(_, state) do
    next = %{state | schedule: %{state.schedule | rejected: state.schedule.rejected + 1}}
    notify(next, :unknown_mailbox)
    {:noreply, next}
  end

  @impl true
  def handle_call(operation, _from, state) do
    {reply, next} = dispatch(operation, state)
    next = settle(next)

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
    if state.status in [:disposed, :failed], do: {:stop, :normal, state}, else: {:noreply, state}
  end

  defp dispatch(:snapshot, state), do: {{:ok, snapshot(state)}, state}
  defp dispatch({:ack, acknowledgement}, state), do: acknowledge(state, acknowledgement)

  defp dispatch({:enqueue, envelope}, %{schedule: schedule, status: status} = state)
       when schedule != nil and status in [:ready, :awaiting_commit] and state.accepted != nil do
    case RootSchedule.admit(schedule, envelope, state.accepted, state.spec) do
      {:ok, item, superseded, next_schedule} ->
        if RootPort.call(state.ports.evaluator, :admit, [item, state.accepted]) == :ok do
          next = %{state | schedule: next_schedule}
          if superseded, do: outcome(next, superseded, :coalesced, nil)
          notify(next, :admitted)
          send(self(), :drain)
          {{:ok, %{receipt: item.receipt, sequence: item.sequence}}, next}
        else
          {{:error, :invalid_ingress},
           %{state | schedule: %{schedule | rejected: schedule.rejected + 1}}}
        end

      {:error, code, next_schedule} ->
        {{:error, code}, %{state | schedule: next_schedule}}
    end
  end

  defp dispatch({:enqueue, _}, state), do: {{:error, :invalid_ingress}, state}

  defp dispatch({:stop, reason}, state) when reason in [:shutdown, :removal],
    do: stopping(state, reason)

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
    old = if state.accepted, do: state.accepted.correlation, else: %{generation: 1, revision: 0}
    generation = old.generation + if(operation == :replace, do: 1, else: 0)
    revision = if operation == :replace, do: 1, else: old.revision + 1

    case RootPort.correlation(spec, generation, revision, state.attempt + 1, operation) do
      {:ok, correlation} ->
        state = %{state | status: phase(operation), attempt: correlation.sequence, error: nil}
        notify(state, :evaluating)
        request = %{spec: spec, operation: operation, correlation: correlation}
        request = if work, do: Map.put(request, :work, work), else: request
        state = %{state | status: :evaluating}
        state = if work, do: %{state | active_correlation: correlation}, else: state
        callback = if work, do: :prepare_scheduled, else: :prepare

        case RootPort.call(state.ports.evaluator, callback, [request, state.accepted]) do
          {:ok, candidate, []} when work != nil ->
            if RootPort.candidate?(candidate, correlation),
              do: submit(state, spec, correlation, candidate, nil),
              else: rejected(state, :semantic_rejected)

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

    cleanup_result =
      if pending.correlation.operation == :replace,
        do: cleanup(state, state.accepted, :replace),
        else: :ok

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

  defp rejected(state, code) do
    if state.accepted == nil or state.status == :stopping do
      failed(state, code)
    else
      next = %{state | pending: nil, status: :ready, error: RootPort.failure(code)}
      notify(next, :rejected)
      {{:error, RootPort.failure(code)}, next}
    end
  end

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

    if state.schedule,
      do: Map.put(value, :scheduling, RootSchedule.metrics(state.schedule)),
      else: value
  end

  defp run_next(state) do
    case RootSchedule.select(state.schedule) do
      {:ok, work, schedule} ->
        next = %{state | schedule: schedule}

        if RootSchedule.valid_dispatch?(work, state.accepted) and
             RootPort.call(state.ports.evaluator, :admit, [work, state.accepted]) == :ok do
          spec =
            if work.kind == :update, do: Map.merge(state.spec, work.payload), else: state.spec

          {_reply, next} = begin(next, spec, :update, work)
          settle(next)
        else
          outcome(next, work, :rejected, :stale_target)
          send(self(), :drain)
          %{next | schedule: RootSchedule.finish(schedule)}
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

        %{state | schedule: RootSchedule.finish(state.schedule), active_correlation: nil}
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
      | schedule: %{RootSchedule.finish(state.schedule) | queue: []},
        active_correlation: nil
    }
  end

  defp outcome(state, item, result, reason) do
    record =
      Map.merge(snapshot(state), %{
        event: :work_outcome,
        work: Map.take(item, [:receipt, :class, :producer, :sequence]),
        result: result,
        reason: reason,
        correlation: state.active_correlation
      })

    RootPort.call(state.ports.host, :notify, [record])
  end

  defp notify(state, event) do
    snapshot = snapshot(state)
    send(state.guardian, {:root_snapshot, self(), snapshot})
    RootPort.call(state.ports.host, :notify, [Map.put(snapshot, :event, event)])
    :ok
  end
end
