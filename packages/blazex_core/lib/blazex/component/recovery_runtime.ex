defmodule BlazeX.Component.RecoveryRuntime do
  @moduledoc false
  alias BlazeX.Component.{RecoveryCleanup, RecoveryPolicy, RootPort, RootProcess}

  def fail(%{recovery: %{failure: failure}} = state, _) when failure != nil do
    next = RecoveryCleanup.run(%{state | accepted: nil}, :fallback_failed)
    terminal(next, :static)
  end

  def fail(state, code) do
    failure = RecoveryPolicy.failure(state, code)

    state = RecoveryCleanup.run(state, :failure)
    cleanup = state.recovery.cleanup
    failure = %{failure | cleanup: cleanup.status}
    recovery = %{state.recovery | failure: failure, cleanup: cleanup}
    state = %{state | recovery: recovery, pending: nil, accepted: nil, error: failure.code}
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

  def stop(state, reason) do
    next = RecoveryCleanup.run(state, reason)
    error = if next.recovery.cleanup.unresolved == 0, do: nil, else: :cleanup_failed
    next = %{next | status: :disposed, pending: nil, accepted: nil, error: error}
    RootProcess.recovery_notify(next, :disposed)
    {if(error, do: {:error, error}, else: :ok), next}
  end

  defp terminal(state, fallback) do
    if state.pending && state.pending.timer, do: Process.cancel_timer(state.pending.timer)

    failure = %{
      state.recovery.failure
      | fallback: fallback,
        cleanup: state.recovery.cleanup.status
    }

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
