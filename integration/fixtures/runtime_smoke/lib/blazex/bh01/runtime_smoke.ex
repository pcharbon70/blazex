defmodule BlazeX.BH01.RuntimeSmoke do
  @moduledoc false

  alias BlazeX.BH01.RuntimeSmoke.{Protocol, Worker}

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
    cancel_result = Process.cancel_timer(cancel_ref)
    :erlang.display({:bxobservation, [timer_cancel_return: cancel_result]})

    sequence =
      receive do
        :cancelled_timer_fired ->
          fail(sequence, :entry, :cancelled_timer_delivered)
      after
        25 ->
          trace(sequence, :entry, :timer_cancelled, :none, :pending)
      end

    sequence = process_ordering_probe(sequence)
    sequence = timer_probe(sequence)
    sequence = protocol_probe(sequence)
    sequence = trace(sequence, :entry, :ready, :none, :pending)
    sequence = host_call_probe(sequence)
    :ok = Supervisor.stop(supervisor, :normal, @receive_timeout)
    drain_normal_exit(supervisor)

    {:ok, teardown_supervisor} = Supervisor.start_link([{Worker, self()}], strategy: :one_for_one)
    {_worker, sequence} = await_worker(sequence, :repeat_tree_started)
    :ok = Supervisor.stop(teardown_supervisor, :normal, @receive_timeout)
    drain_normal_exit(teardown_supervisor)
    sequence = trace(sequence, :supervisor, :repeat_teardown, :none, :pending)
    mailbox_observation()
    _sequence = trace(sequence, :entry, :shutdown, :none, :complete)
    :ok
  catch
    {:fixture_failure, reason} ->
      trace(999, :entry, :failed, reason, :incomplete)
      {:error, reason}
  end

  defp process_ordering_probe(sequence) do
    send(self(), {:ordered, 2})
    send(self(), {:ordered, 1})

    sequence =
      receive do
        {:ordered, 1} -> trace(sequence, :entry, :selective_receive, :none, :pending)
      after
        @receive_timeout -> fail(sequence, :entry, :selective_receive_timeout)
      end

    receive do
      {:ordered, 2} -> trace(sequence, :entry, :mailbox_order_preserved, :none, :pending)
    after
      @receive_timeout -> fail(sequence, :entry, :mailbox_order_timeout)
    end
  end

  defp timer_probe(sequence) do
    started = :erlang.monotonic_time(:millisecond)
    Process.send_after(self(), {:repeat_timer, 1}, 1)

    sequence =
      receive do
        {:repeat_timer, 1} ->
          Process.send_after(self(), {:repeat_timer, 2}, 1)
          trace(sequence, :entry, :repeated_timer_tick_1, :none, :pending)
      after
        @receive_timeout -> fail(sequence, :entry, :repeated_timer_1_timeout)
      end

    sequence =
      receive do
        {:repeat_timer, 2} -> trace(sequence, :entry, :repeated_timer_tick_2, :none, :pending)
      after
        @receive_timeout -> fail(sequence, :entry, :repeated_timer_2_timeout)
      end

    sequence =
      receive do
        :message_that_never_arrives -> fail(sequence, :entry, :unexpected_timeout_message)
      after
        1 -> trace(sequence, :entry, :bounded_timeout, :none, :pending)
      end

    send(self(), {:async_result, @generation - 1})
    send(self(), {:async_result, @generation})

    sequence =
      receive do
        {:async_result, stale} when stale != @generation ->
          trace(sequence, :entry, :stale_generation_rejected, :none, :pending)
      after
        @receive_timeout -> fail(sequence, :entry, :stale_generation_timeout)
      end

    sequence =
      receive do
        {:async_result, @generation} ->
          trace(sequence, :entry, :current_generation_accepted, :none, :pending)
      after
        @receive_timeout -> fail(sequence, :entry, :current_generation_timeout)
      end

    Process.send_after(self(), :late_result, 5)

    sequence =
      receive do
        :late_result -> fail(sequence, :entry, :late_result_arrived_early)
      after
        1 -> trace(sequence, :entry, :late_result_timed_out, :none, :pending)
      end

    sequence =
      receive do
        :late_result -> trace(sequence, :entry, :late_result_drained, :none, :pending)
      after
        @receive_timeout -> fail(sequence, :entry, :late_result_missing)
      end

    finished = :erlang.monotonic_time(:millisecond)
    :erlang.display({:bxobservation, [monotonic_elapsed_ms: finished - started]})
    sequence
  end

  defp protocol_probe(sequence) do
    state = Protocol.new_state(@generation)

    request = %{
      "version" => 1,
      "request_id" => 41,
      "generation" => @generation,
      "tag" => "echo",
      "payload" => %{"scalar" => 7, "items" => [true, nil, "ok"]}
    }

    {:ok, response, state} = Protocol.accept(request, state)
    true = response["request_id"] == 41 and response["generation"] == @generation
    {:ok, state} = Protocol.settle_reply(41, @generation, state)
    sequence = trace(sequence, :protocol, :request_response_matched, :none, :pending)
    {:error, :duplicate_request, state} = Protocol.accept(request, state)
    sequence = trace(sequence, :protocol, :duplicate_request_rejected, :none, :pending)
    {:error, :duplicate_reply, state} = Protocol.settle_reply(41, @generation, state)
    sequence = trace(sequence, :protocol, :duplicate_reply_rejected, :none, :pending)

    {:error, :stale_generation, state} =
      Protocol.settle_reply(41, @generation + 1, state)

    sequence = trace(sequence, :protocol, :stale_reply_rejected, :none, :pending)

    {:error, :unknown_tag, state} =
      Protocol.accept(%{request | "request_id" => 43, "tag" => "eval"}, state)

    sequence = trace(sequence, :protocol, :unknown_tag_rejected, :none, :pending)

    {:error, :forbidden_or_non_string_key, state} =
      Protocol.accept(%{request | "request_id" => 44, "payload" => %{"secret" => "value"}}, state)

    sequence = trace(sequence, :protocol, :forbidden_capability_rejected, :none, :pending)
    {:ok, _response, state} = Protocol.accept(%{request | "request_id" => 45}, state)
    cancelled = Protocol.cancel(45, state)
    true = 45 in cancelled.cancelled_request_ids
    sequence = trace(sequence, :protocol, :cancellation_recorded, :none, :pending)
    {:error, :cancelled_request, ^cancelled} = Protocol.settle_reply(45, @generation, cancelled)
    sequence = trace(sequence, :protocol, :cancelled_reply_rejected, :none, :pending)
    {:error, :host, :denied} = Protocol.classify_failure({:host_error, :denied})
    sequence = trace(sequence, :protocol, :host_error_classified, :none, :pending)
    {:error, :runtime, :crashed} = Protocol.classify_failure({:runtime_error, :crashed})
    sequence = trace(sequence, :protocol, :runtime_error_classified, :none, :pending)
    disposed = Protocol.dispose(cancelled)
    {:error, :disposed, ^disposed} = Protocol.settle_reply(41, @generation, disposed)
    trace(sequence, :protocol, :post_disposal_rejected, :none, :pending)
  end

  defp host_call_probe(sequence) do
    if :erlang.system_info(:machine) == ~c"BEAM" do
      trace(sequence, :host_boundary, :reference_beam_skipped, :none, :pending)
    else
      trace(sequence, :host_boundary, :node_direct_call_deferred, :none, :pending)
    end
  end

  defp mailbox_observation do
    case :erlang.process_info(self(), :message_queue_len) do
      {:message_queue_len, length} ->
        :erlang.display({:bxobservation, [message_queue_len: length]})

      other ->
        :erlang.display({:bxobservation, [message_queue_len: other]})
    end
  end

  defp drain_normal_exit(pid) do
    receive do
      {:EXIT, ^pid, :normal} -> :ok
    after
      0 -> :ok
    end
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
         fixture_version: :"0.0.0-bh01",
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
