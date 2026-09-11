defmodule BlazeX.Component.RootGuardian do
  @moduledoc false
  use GenServer
  alias BlazeX.Component.{ActionRuntime, RootPort, RootProcess, RootSchedule, SchedulingPort}

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({spec, ports}), do: init({spec, ports, nil})

  def init({spec, ports, policy}), do: init({spec, ports, policy, nil})

  def init({spec, ports, policy, actions}) do
    with {:ok, spec} <- RootPort.normalize(spec),
         true <- RootPort.ports?(ports),
         {:ok, _} <- RootSchedule.new(policy),
         :ok <- ActionRuntime.validate(actions),
         true <- policy == nil or SchedulingPort.supported?(ports.evaluator),
         true <-
           actions == nil or
             (policy != nil and function_exported?(elem(ports.evaluator, 0), :admit_action, 3)) do
      Process.flag(:trap_exit, true)
      {:ok, worker} = RootProcess.start_link({self(), spec, ports, policy, actions})

      {:ok,
       %{
         worker: worker,
         ports: ports,
         handle: RootPort.handle(spec),
         snapshot: nil,
         work: [],
         timer_refs: [],
         actions: nil
       }}
    else
      _ -> {:stop, :invalid_start}
    end
  end

  @impl true
  def handle_call(:terminal, _from, state) do
    {:reply, {terminal?(state), state.handle.instance}, state}
  end

  def handle_call({handle, operation}, _from, state) do
    cond do
      handle != state.handle ->
        {:reply, {:error, :stale}, state}

      operation == :snapshot and terminal?(state) ->
        {:reply, {:ok, state.snapshot}, state}

      match?({:stop, _}, operation) and terminal?(state) ->
        {:reply, :ok, state}

      terminal?(state) ->
        {:reply, {:error, :terminal}, state}

      true ->
        try do
          {reply, snapshot} = GenServer.call(state.worker, operation, 60_000)
          state = drain_checkpoints(state)
          {:reply, reply, %{state | snapshot: snapshot}}
        catch
          :exit, _ ->
            next = crashed(state)
            {:reply, {:error, :crashed}, next}
        end
    end
  end

  @impl true
  def handle_info({:root_actions, worker, actions}, %{worker: worker} = state),
    do: {:noreply, %{state | actions: actions}}

  def handle_info({:root_work, worker, work, refs}, %{worker: worker} = state),
    do: {:noreply, %{state | work: work, timer_refs: refs}}

  def handle_info({:root_work_done, worker, receipt}, %{worker: worker} = state),
    do: {:noreply, %{state | work: Enum.reject(state.work, &(&1.receipt == receipt))}}

  def handle_info({:root_snapshot, worker, snapshot}, %{worker: worker} = state) do
    if terminal?(state), do: {:noreply, state}, else: {:noreply, %{state | snapshot: snapshot}}
  end

  def handle_info({:EXIT, worker, _private_reason}, %{worker: worker} = state) do
    {:noreply, if(terminal?(state), do: %{state | worker: nil}, else: crashed(state))}
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def terminate(_, state) do
    ActionRuntime.close(state.actions, :shutdown)
    Enum.each(state.timer_refs, &Process.cancel_timer/1)
    if is_pid(state.worker), do: :erlang.exit(state.worker, :shutdown)
    :ok
  end

  @impl true
  def format_status(status),
    do:
      Map.new(status, fn {key, _} ->
        {key, if(key == :log, do: [], else: :redacted_root_guardian)}
      end)

  defp terminal?(%{snapshot: %{status: status}}), do: status in [:disposed, :failed]
  defp terminal?(_), do: false

  defp crashed(state) do
    state = drain_checkpoints(state)
    actions = ActionRuntime.close(state.actions, :crashed)
    Enum.each(state.timer_refs, &Process.cancel_timer/1)

    snapshot =
      state.snapshot ||
        %{
          contract: RootPort.version(),
          handle: state.handle,
          status: :starting,
          accepted: nil,
          pending: nil,
          attempt: 0,
          error: nil
        }

    snapshot = %{snapshot | status: :failed, pending: nil, error: :crashed}

    snapshot =
      if actions, do: Map.put(snapshot, :actions, ActionRuntime.snapshot(actions)), else: snapshot

    snapshot =
      if Map.has_key?(snapshot, :scheduling) do
        snapshot
        |> Map.update!(:scheduling, fn metrics ->
          %{
            metrics
            | depth: 0,
              queued: 0,
              active: 0,
              reserved: 0,
              queued_receipts: [],
              classes: Map.new(metrics.classes, fn {key, _} -> {key, 0} end)
          }
        end)
        |> Map.update!(:timers, fn timers ->
          %{
            timers
            | active: 0,
              entries: [],
              canceled: min(timers.canceled + timers.active, 9_007_199_254_740_991)
          }
        end)
      else
        snapshot
      end

    Enum.each(state.work, fn work ->
      {correlation, work} = Map.pop(work, :correlation)

      RootPort.call(state.ports.host, :notify, [
        Map.merge(snapshot, %{
          event: :work_outcome,
          work: work,
          result: :canceled,
          reason: :crashed,
          correlation: correlation
        })
      ])
    end)

    RootPort.call(state.ports.host, :notify, [Map.put(snapshot, :event, :crashed)])
    if is_pid(state.worker), do: :erlang.exit(state.worker, :kill)
    %{state | snapshot: snapshot, worker: nil, work: [], timer_refs: [], actions: actions}
  end

  defp drain_checkpoints(%{worker: worker} = state) do
    receive do
      {:root_actions, ^worker, actions} ->
        drain_checkpoints(%{state | actions: actions})

      {:root_work, ^worker, work, refs} ->
        drain_checkpoints(%{state | work: work, timer_refs: refs})

      {:root_work_done, ^worker, receipt} ->
        drain_checkpoints(%{state | work: Enum.reject(state.work, &(&1.receipt == receipt))})

      {:root_snapshot, ^worker, snapshot} ->
        drain_checkpoints(%{state | snapshot: snapshot})
    after
      0 -> state
    end
  end
end
