defmodule BlazeX.Component.RootProcess do
  @moduledoc false
  use GenServer
  alias BlazeX.Component.RootPort

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({guardian, spec, ports}) do
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
       error: nil
     }}
  end

  @impl true
  def handle_info(:boot, state) do
    notify(state, :registered)
    {_reply, next} = begin(state, state.spec, :mount)
    info_result(next)
  end

  def handle_info({:deadline, correlation}, %{pending: %{correlation: correlation}} = state) do
    {_reply, next} = abandon(state, :timeout)
    info_result(next)
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def handle_call(operation, _from, state) do
    {reply, next} = dispatch(operation, state)

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

  defp dispatch({:stop, reason}, state) when reason in [:shutdown, :removal],
    do: stopping(state, reason)

  defp dispatch(_operation, %{status: status} = state) when status != :ready,
    do: {{:error, :busy}, state}

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

  defp begin(state, spec, operation) do
    old = if state.accepted, do: state.accepted.correlation, else: %{generation: 1, revision: 0}
    generation = old.generation + if(operation == :replace, do: 1, else: 0)
    revision = if operation == :replace, do: 1, else: old.revision + 1

    case RootPort.correlation(spec, generation, revision, state.attempt + 1, operation) do
      {:ok, correlation} ->
        state = %{state | status: phase(operation), attempt: correlation.sequence, error: nil}
        notify(state, :evaluating)
        request = %{spec: spec, operation: operation, correlation: correlation}
        state = %{state | status: :evaluating}

        case RootPort.call(state.ports.evaluator, :prepare, [request, state.accepted]) do
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
    %{
      contract: RootPort.version(),
      handle: RootPort.handle(state.spec),
      status: state.status,
      accepted: RootPort.summary(state.accepted),
      pending: if(state.pending, do: state.pending.correlation, else: nil),
      attempt: state.attempt,
      error: state.error
    }
  end

  defp notify(state, event) do
    snapshot = snapshot(state)
    send(state.guardian, {:root_snapshot, self(), snapshot})
    RootPort.call(state.ports.host, :notify, [Map.put(snapshot, :event, event)])
    :ok
  end
end
