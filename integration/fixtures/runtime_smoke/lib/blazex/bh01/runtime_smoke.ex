defmodule BlazeX.BH01.RuntimeSmoke do
  @moduledoc false

  alias BlazeX.BH01.RuntimeSmoke.Worker

  @generation 1
  @scenario :runtime_smoke
  @receive_timeout 1_000

  def start do
    Process.flag(:trap_exit, true)
    sequence = trace(1, :entry, :starting, :none, :pending)
    identity()

    {:ok, supervisor} =
      Supervisor.start_link([{Worker, self()}], strategy: :one_for_one)

    {worker, sequence} = await_worker(sequence, :initial_worker)
    monitor = Process.monitor(worker)
    send(worker, {:echo, self(), 1, :bounded_payload})

    sequence =
      receive do
        {:echo_reply, ^worker, 1, :bounded_payload} ->
          trace(sequence, :worker, :message_round_trip, :none, :pending)
      after
        @receive_timeout ->
          fail(sequence, :worker, :message_timeout)
      end

    send(worker, :controlled_crash)

    sequence =
      receive do
        {:worker_crashing, ^worker} ->
          trace(sequence, :worker, :controlled_crash, :none, :pending)
      after
        @receive_timeout ->
          fail(sequence, :worker, :crash_not_observed)
      end

    sequence =
      receive do
        {:DOWN, ^monitor, :process, ^worker, :controlled_crash} ->
          trace(sequence, :supervisor, :worker_exit_observed, :none, :pending)
      after
        @receive_timeout ->
          fail(sequence, :supervisor, :down_not_observed)
      end

    {_replacement, sequence} = await_worker(sequence, :worker_restarted)

    Process.send_after(self(), {:timer_fired, @generation}, 1)

    sequence =
      receive do
        {:timer_fired, @generation} ->
          trace(sequence, :entry, :timer_fired, :none, :pending)
      after
        @receive_timeout ->
          fail(sequence, :entry, :timer_timeout)
      end

    cancel_ref = Process.send_after(self(), :cancelled_timer_fired, 500)
    remaining = Process.cancel_timer(cancel_ref)

    sequence =
      if is_integer(remaining) do
        trace(sequence, :entry, :timer_cancelled, :none, :pending)
      else
        fail(sequence, :entry, :timer_cancel_failed)
      end

    sequence = trace(sequence, :entry, :ready, :none, :pending)
    :ok = Supervisor.stop(supervisor, :normal, @receive_timeout)
    _sequence = trace(sequence, :entry, :shutdown, :none, :complete)
    :ok
  catch
    {:fixture_failure, reason} ->
      trace(999, :entry, :failed, reason, :incomplete)
      {:error, reason}
  end

  defp await_worker(sequence, result) do
    receive do
      {:worker_started, pid} when is_pid(pid) ->
        {pid, trace(sequence, :worker, result, :none, :pending)}
    after
      @receive_timeout ->
        fail(sequence, :supervisor, :worker_start_timeout)
    end
  end

  defp identity do
    :erlang.display(
      {:bxidentity,
       [
         fixture: :blazex_bh01_runtime_smoke,
         fixture_version: :'0.0.0-bh01',
         otp_release: :erlang.system_info(:otp_release),
         machine: :erlang.system_info(:machine)
       ]}
    )
  end

  defp trace(sequence, process, result, error, cleanup) do
    :erlang.display(
      {:bxtrace,
       [
         generation: @generation,
         scenario: @scenario,
         process: process,
         sequence: sequence,
         result: result,
         error: error,
         cleanup: cleanup
       ]}
    )

    sequence + 1
  end

  defp fail(sequence, process, reason) do
    trace(sequence, process, :failed, reason, :incomplete)
    throw({:fixture_failure, reason})
  end
end
