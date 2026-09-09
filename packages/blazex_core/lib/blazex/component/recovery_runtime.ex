defmodule BlazeX.Component.RecoveryRuntime do
  @moduledoc false
  alias BlazeX.Component.{RecoveryPolicy, RootPort, RootProcess}

  def fail(%{recovery: %{failure: failure}} = state, _) when failure != nil,
    do: terminal(state, :static)

  def fail(state, code) do
    failure = RecoveryPolicy.failure(state, code)

    if state.pending do
      if state.pending.timer, do: Process.cancel_timer(state.pending.timer)
      RootPort.call(state.ports.renderer, :cancel, [state.pending.correlation])
    end

    state = RootProcess.recovery_close(state, :failure)

    cleanup =
      if state.accepted,
        do: RootPort.call(state.ports.evaluator, :cleanup, [state.accepted, :shutdown]),
        else: :ok

    cleanup = %{status: if(cleanup == :ok, do: :completed, else: :failed)}
    failure = %{failure | cleanup: cleanup.status}
    recovery = %{state.recovery | failure: failure, cleanup: cleanup}
    state = %{state | recovery: recovery, pending: nil, error: failure.code}
    correlation = failure.correlation

    {:ok, correlation} =
      RootPort.correlation(
        state.spec,
        correlation.generation,
        correlation.revision + 1,
        state.attempt + 1,
        :failure
      )

    state = %{state | attempt: correlation.sequence}
    RootProcess.recovery_notify(state, :root_failure)

    case RootPort.call(state.ports.evaluator, :fallback, [correlation, failure]) do
      {:ok, candidate} -> RootProcess.recovery_submit(state, correlation, candidate)
      _ -> terminal(state, :static)
    end
  end

  def fallback_committed(state), do: terminal(state, :committed)

  defp terminal(state, fallback) do
    if state.pending && state.pending.timer, do: Process.cancel_timer(state.pending.timer)
    failure = %{state.recovery.failure | fallback: fallback}

    next = %{
      state
      | recovery: %{state.recovery | failure: failure},
        status: :failed,
        pending: nil,
        accepted: nil
    }

    RootProcess.recovery_notify(
      next,
      if(fallback == :static, do: :static_fallback, else: :fallback_committed)
    )

    {:ok, next}
  end
end
