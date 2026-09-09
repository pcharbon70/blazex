defmodule BlazeX.Component.RecoveryGuardian do
  @moduledoc false
  use GenServer
  alias BlazeX.Component.{Action, RecoveryPolicy, RecoveryPort, RootPort, RootProcess}

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({spec, ports, policy, actions, config}) do
    true = RecoveryPolicy.validate(config)
    true = function_exported?(elem(ports.evaluator, 0), :fallback, 3)
    Process.flag(:trap_exit, true)

    ports = %{
      ports
      | renderer: {RecoveryPort, {ports.renderer, config.port_timeout_ms}},
        host: {RecoveryPort, {ports.host, config.port_timeout_ms}}
    }

    recovery = %{
      config: config,
      generation: 1,
      sequence: 0,
      retry_count: 0,
      failure: nil,
      cleanup: nil
    }

    {:ok, worker} = RootProcess.start_link({self(), spec, ports, policy, actions, recovery})

    {:ok,
     %{
       worker: worker,
       spec: spec,
       ports: ports,
       policy: policy,
       actions_config: actions,
       recovery: recovery,
       snapshot: nil,
       checkpoint: nil,
       actions: nil
     }}
  end

  @impl true
  def handle_call(:terminal, _, state),
    do: {:reply, {terminal?(state), state.spec.instance}, state}

  def handle_call({handle, operation}, _, state) do
    cond do
      handle != RootPort.handle(state.spec) ->
        {:reply, {:error, :stale}, state}

      match?({:retry, _}, operation) ->
        {reply, next} = retry(state, elem(operation, 1))
        {:reply, reply, next}

      operation == :snapshot and terminal?(state) ->
        {:reply, {:ok, state.snapshot}, state}

      match?({:stop, _}, operation) and terminal?(state) ->
        {:reply, :ok, state}

      terminal?(state) ->
        {:reply, {:error, :terminal}, state}

      true ->
        try do
          {reply, snapshot} = GenServer.call(state.worker, operation, 5000)
          state = drain(state)
          {:reply, reply, %{state | snapshot: snapshot}}
        catch
          :exit, _ -> {:reply, {:error, :crashed}, crashed(drain(state))}
        end
    end
  end

  @impl true
  def handle_info({:recovery_checkpoint, worker, checkpoint}, %{worker: worker} = state),
    do: {:noreply, %{state | checkpoint: checkpoint}}

  def handle_info({:root_snapshot, worker, snapshot}, %{worker: worker} = state),
    do: {:noreply, %{state | snapshot: snapshot}}

  def handle_info({:root_actions, worker, actions}, %{worker: worker} = state),
    do: {:noreply, %{state | actions: actions}}

  def handle_info({:EXIT, worker, _}, %{worker: worker} = state) do
    state = drain(state)
    {:noreply, if(terminal?(state), do: %{state | worker: nil}, else: crashed(state))}
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def terminate(_, state) do
    if is_pid(state.worker), do: Process.exit(state.worker, :shutdown)
    :ok
  end

  @impl true
  def format_status(status),
    do:
      Map.new(status, fn {key, _} ->
        {key, if(key == :log, do: [], else: :redacted_recovery_guardian)}
      end)

  defp terminal?(%{snapshot: %{status: status}}), do: status in [:disposed, :failed]
  defp terminal?(_), do: false

  defp retry(state, request) do
    true = terminal?(state) and state.snapshot.status == :failed
    true = Action.keys?(request, [:generation, :fingerprint, :source, :spec])
    failure = state.snapshot.recovery.failure

    true =
      request.generation == failure.correlation.generation and
        request.fingerprint == failure.fingerprint

    true =
      request.source in [:user, :host, :changed] and
        Map.fetch!(state.recovery.config, request.source)

    true = failure.cleanup == :completed and failure.code != :runtime_loss
    {:ok, spec} = RootPort.normalize(request.spec)
    true = RootPort.handle(spec) == RootPort.handle(state.spec)
    generation = failure.correlation.generation + 1
    true = Action.positive?(generation)

    recovery = %{
      state.recovery
      | generation: generation,
        sequence: state.snapshot.attempt,
        retry_count: state.snapshot.recovery.retry_count + 1,
        failure: nil,
        cleanup: nil
    }

    if is_pid(state.worker), do: Process.exit(state.worker, :kill)

    {:ok, worker} =
      RootProcess.start_link(
        {self(), spec, state.ports, state.policy, state.actions_config, recovery}
      )

    {{:ok, %{generation: generation, source: request.source}},
     %{
       state
       | worker: worker,
         spec: spec,
         snapshot: nil,
         checkpoint: nil,
         actions: nil,
         recovery: recovery
     }}
  rescue
    _ -> {{:error, :retry_rejected}, state}
  end

  defp crashed(%{checkpoint: checkpoint} = state) when checkpoint != nil do
    if is_pid(state.worker), do: Process.exit(state.worker, :kill)

    checkpoint = %{
      checkpoint
      | actions: state.actions || checkpoint.actions,
        guardian: self(),
        status: :starting
    }

    {:ok, worker} = RootProcess.start_link({:recovery_crash, checkpoint})
    %{state | worker: worker, snapshot: nil, checkpoint: checkpoint}
  end

  defp crashed(state) do
    {:ok, worker} =
      RootProcess.start_link(
        {self(), state.spec, state.ports, state.policy, state.actions_config, state.recovery}
      )

    %{state | worker: worker}
  end

  defp drain(state) do
    worker = state.worker

    receive do
      {:recovery_checkpoint, ^worker, checkpoint} -> drain(%{state | checkpoint: checkpoint})
      {:root_snapshot, ^worker, snapshot} -> drain(%{state | snapshot: snapshot})
      {:root_actions, ^worker, actions} -> drain(%{state | actions: actions})
    after
      0 -> state
    end
  end
end
