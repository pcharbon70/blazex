defmodule BlazeX.Component.RecoveryGuardian do
  @moduledoc false
  use GenServer

  alias BlazeX.Component.{
    Action,
    RecoveryCleanup,
    RecoveryPolicy,
    RecoveryPort,
    RecoveryRuntime,
    RootPort,
    RootProcess
  }

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({spec, ports, policy, actions, config}) do
    true = RecoveryPolicy.validate(config)
    true = match?({:static, _}, spec.fallback)
    true = function_exported?(elem(ports.evaluator, 0), :fallback, 3)

    true =
      Enum.all?([dispose: 2, force_cleanup: 2], fn {name, arity} ->
        function_exported?(elem(ports.renderer, 0), name, arity)
      end)

    actions =
      if actions do
        true = function_exported?(elem(actions.port, 0), :force_cleanup, 2)
        %{actions | port: {RecoveryPort, {actions.port, config.port_timeout_ms}}}
      else
        nil
      end

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
      cleanup: nil,
      correlation: nil,
      cleaned_generation: nil
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
       actions: nil,
       ledger: RecoveryPolicy.ledger(),
       automatic_timer: nil
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

      match?({:stop, _}, operation) and elem(operation, 1) not in [:shutdown, :removal] ->
        {:reply, {:error, :invalid_request}, state}

      operation == :snapshot and terminal?(state) ->
        {:reply, {:ok, decorate(state.snapshot, state)}, state}

      match?({:stop, _}, operation) and terminal?(state) ->
        if state.snapshot.status == :disposed do
          {:reply, if(state.snapshot.error, do: {:error, state.snapshot.error}, else: :ok), state}
        else
          cancel_automatic(state)
          if is_pid(state.worker), do: Process.exit(state.worker, :kill)
          {reply, checkpoint} = RecoveryRuntime.stop(state.checkpoint, elem(operation, 1))

          {:reply, reply,
           %{
             state
             | worker: nil,
               checkpoint: checkpoint,
               snapshot: RootProcess.recovery_snapshot(checkpoint),
               automatic_timer: nil
           }}
        end

      terminal?(state) ->
        {:reply, {:error, :terminal}, state}

      true ->
        try do
          {reply, snapshot} = GenServer.call(state.worker, operation, 5000)
          state = drain(state)
          state = schedule_automatic(%{state | snapshot: snapshot})
          reply = if operation == :snapshot, do: {:ok, decorate(snapshot, state)}, else: reply
          {:reply, reply, state}
        catch
          :exit, _ ->
            next = drain(state)

            if terminal?(next) do
              next = schedule_automatic(%{next | worker: nil})

              reply =
                if operation == :snapshot,
                  do: {:ok, decorate(next.snapshot, next)},
                  else: {:error, :terminal}

              {:reply, reply, next}
            else
              {:reply, {:error, :crashed}, crashed(next)}
            end
        end
    end
  end

  @impl true
  def handle_info({:recovery_checkpoint, worker, checkpoint}, %{worker: worker} = state),
    do: {:noreply, %{state | checkpoint: checkpoint}}

  def handle_info({:root_snapshot, worker, snapshot}, %{worker: worker} = state),
    do: {:noreply, schedule_automatic(%{state | snapshot: snapshot})}

  def handle_info({:root_actions, worker, actions}, %{worker: worker} = state),
    do: {:noreply, %{state | actions: actions}}

  def handle_info({:EXIT, worker, _}, %{worker: worker} = state) do
    state = drain(state)
    {:noreply, if(terminal?(state), do: %{state | worker: nil}, else: crashed(state))}
  end

  def handle_info(
        {:automatic_retry, token, generation, fingerprint},
        %{automatic_timer: {_, token}} = state
      ) do
    {_, next} =
      retry(
        %{state | automatic_timer: nil},
        %{generation: generation, fingerprint: fingerprint, source: :automatic, spec: state.spec},
        true
      )

    {:noreply, next}
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def terminate(_, state) do
    cancel_automatic(state)
    if is_pid(state.worker), do: Process.exit(state.worker, :kill)

    if state.checkpoint && (not terminal?(state) or state.snapshot.status != :disposed) do
      RecoveryCleanup.run(
        %{state.checkpoint | actions: state.actions || state.checkpoint.actions},
        :shutdown
      )
    end

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

  defp retry(state, request, automatic \\ false) do
    true = terminal?(state) and state.snapshot.status == :failed
    true = Action.keys?(request, [:generation, :fingerprint, :source, :spec])
    failure = state.snapshot.recovery.failure

    true =
      request.generation == failure.correlation.generation and
        request.fingerprint == failure.fingerprint

    true =
      (request.source in [:user, :host, :changed] or (automatic and request.source == :automatic)) and
        Map.fetch!(state.recovery.config, request.source)

    true = failure.cleanup == :completed and failure.code != :runtime_loss
    {:ok, spec} = RootPort.normalize(request.spec)
    true = RootPort.handle(spec) == RootPort.handle(state.spec)
    generation = failure.correlation.generation + 1
    true = Action.positive?(generation)

    {decision, ledger} =
      RecoveryPolicy.admit(
        state.ledger,
        request.source,
        request.fingerprint,
        generation,
        System.monotonic_time(:millisecond),
        state.recovery.config.backoff_ms
      )

    if decision == :admitted do
      restart(%{state | ledger: ledger}, spec, generation, request.source)
    else
      {{:error, decision}, %{state | ledger: ledger}}
    end
  rescue
    _ -> {{:error, :retry_rejected}, state}
  end

  defp restart(state, spec, generation, source) do
    cancel_automatic(state)
    if is_pid(state.worker), do: Process.exit(state.worker, :kill)
    checkpoint = RecoveryCleanup.run(%{state.checkpoint | accepted: nil}, :retry)

    if checkpoint.recovery.cleanup.unresolved != 0 do
      {{:error, :cleanup_failed},
       %{
         state
         | worker: nil,
           automatic_timer: nil,
           checkpoint: checkpoint,
           snapshot: RootProcess.recovery_snapshot(checkpoint)
       }}
    else
      recovery = %{
        state.recovery
        | generation: generation,
          sequence: state.snapshot.attempt,
          retry_count: state.snapshot.recovery.retry_count + 1,
          failure: nil,
          cleanup: nil
      }

      {:ok, worker} =
        RootProcess.start_link(
          {self(), spec, state.ports, state.policy, state.actions_config, recovery}
        )

      {{:ok, %{generation: generation, source: source}},
       %{
         state
         | worker: worker,
           spec: spec,
           snapshot: nil,
           checkpoint: nil,
           actions: nil,
           recovery: recovery,
           automatic_timer: nil
       }}
    end
  end

  defp decorate(snapshot, state), do: put_in(snapshot, [:recovery, :restart], state.ledger)
  defp cancel_automatic(%{automatic_timer: {reference, _}}), do: Process.cancel_timer(reference)
  defp cancel_automatic(_), do: :ok

  defp schedule_automatic(%{snapshot: %{status: :failed}, automatic_timer: nil} = state) do
    failure = state.snapshot.recovery.failure

    if state.recovery.config.automatic and state.ledger.terminal == nil and
         failure != nil and failure.cleanup == :completed and failure.code != :runtime_loss do
      token = make_ref()

      reference =
        Process.send_after(
          self(),
          {:automatic_retry, token, failure.correlation.generation, failure.fingerprint},
          state.recovery.config.backoff_ms
        )

      %{state | automatic_timer: {reference, token}}
    else
      state
    end
  end

  defp schedule_automatic(state), do: state

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
