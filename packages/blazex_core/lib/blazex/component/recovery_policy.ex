defmodule BlazeX.Component.RecoveryPolicy do
  @moduledoc "Closed root recovery policy and redacted failure identity."
  alias BlazeX.Component.{Action, NestedTable, RootPort}
  def ledger, do: %{automatic: [], attempts: [], terminal: nil, maximum: 0}

  def admit(ledger, source, fingerprint, generation, now, backoff) do
    true = source in [:automatic, :user, :host, :changed]
    automatic = Enum.filter(ledger.automatic, &(now - &1 < 5000))

    reason =
      cond do
        source == :automatic and ledger.terminal != nil ->
          ledger.terminal

        source == :automatic and length(automatic) >= 3 ->
          :restart_intensity

        source == :automatic and automatic != [] and now - List.last(automatic) < backoff ->
          :backoff

        true ->
          :admitted
      end

    automatic =
      if source == :automatic and reason == :admitted, do: automatic ++ [now], else: automatic

    row = %{
      source: source,
      fingerprint: fingerprint,
      generation: generation,
      monotonic_ms: now,
      backoff_ms: backoff,
      decision: reason,
      automatic_in_window: length(automatic)
    }

    ledger = %{
      ledger
      | automatic: automatic,
        attempts: Enum.take(ledger.attempts ++ [row], -128),
        terminal: if(reason == :restart_intensity, do: reason, else: ledger.terminal),
        maximum: max(ledger.maximum, length(automatic))
    }

    {reason, ledger}
  end

  def validate(config) do
    Action.keys?(config, [:automatic, :user, :host, :changed, :backoff_ms, :port_timeout_ms]) and
      Enum.all?([config.automatic, config.user, config.host, config.changed], &is_boolean/1) and
      is_integer(config.backoff_ms) and config.backoff_ms in 100..1000 and
      is_integer(config.port_timeout_ms) and config.port_timeout_ms in 10..250
  rescue
    _ -> false
  end

  def failure(state, code) do
    correlation =
      cond do
        state.pending ->
          state.pending.correlation

        state.active_correlation ->
          state.active_correlation

        state.recovery.correlation ->
          state.recovery.correlation

        state.accepted ->
          state.accepted.correlation

        true ->
          elem(
            RootPort.correlation(
              state.spec,
              state.recovery.generation,
              1,
              max(state.attempt, 1),
              :mount
            ),
            1
          )
      end

    stage =
      cond do
        code == :crashed -> :crash
        code in [:renderer_rejected, :rollback_failed, :timeout] -> :renderer
        code == :cleanup_failed -> :disposal
        code == :runtime_loss -> :runtime
        state.schedule && state.schedule.active -> state.schedule.active.kind
        true -> correlation.operation
      end

    code = if code in [:runtime_loss, :timed_out], do: code, else: RootPort.failure(code)

    owner =
      if state.schedule && state.schedule.active,
        do: state.schedule.active.target,
        else: %{root: state.spec.root, generation: correlation.generation, path: []}

    %{
      version: 1,
      code: code,
      stage: stage,
      owner: owner,
      correlation: correlation,
      fingerprint: NestedTable.digest({code, stage, state.spec.public_id}),
      retry_count: state.recovery.retry_count,
      cleanup: :requested,
      fallback: :requested,
      retry_visible: state.recovery.config.user,
      reload_visible: true,
      static_fallback: elem(state.spec.fallback, 1)
    }
  end
end
