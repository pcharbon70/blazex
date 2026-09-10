defmodule BlazeX.RecoveryPolicyTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{RecoveryPolicy, RecoveryPort}

  defmodule Ports do
    def call(:slow), do: Process.sleep(100)

    def call({:sleep, milliseconds}) do
      Process.sleep(milliseconds)
      :ok
    end

    def call(:ok), do: :ok
    def call(:crash), do: raise("private")
    def call(:exit), do: exit(:private)
  end

  test "three automatic restarts in five seconds then terminal regardless of fingerprint" do
    ledger =
      Enum.reduce(1..3, RecoveryPolicy.ledger(), fn n, ledger ->
        assert {:admitted, next} =
                 RecoveryPolicy.admit(ledger, :automatic, "same", n + 1, n * 100, 100)

        next
      end)

    assert {:restart_intensity, exhausted} =
             RecoveryPolicy.admit(ledger, :automatic, "changed", 5, 400, 100)

    assert exhausted.maximum == 3 and exhausted.terminal == :restart_intensity

    assert {:restart_intensity, _} =
             RecoveryPolicy.admit(exhausted, :automatic, "same", 5, 6000, 100)

    assert {:admitted, explicit} = RecoveryPolicy.admit(exhausted, :user, "same", 5, 6000, 100)
    assert explicit.terminal == :restart_intensity
  end

  test "window and bounded public retry inventory" do
    {:admitted, first} = RecoveryPolicy.admit(RecoveryPolicy.ledger(), :automatic, "a", 2, 0, 100)
    assert {:backoff, _} = RecoveryPolicy.admit(first, :automatic, "a", 3, 50, 100)
    assert {:admitted, next} = RecoveryPolicy.admit(first, :automatic, "a", 3, 5000, 100)
    assert next.automatic == [5000]

    ledger =
      Enum.reduce(1..150, next, fn n, ledger ->
        elem(RecoveryPolicy.admit(ledger, :host, "a", n + 3, n + 5000, 100), 1)
      end)

    assert length(ledger.attempts) == 128
  end

  test "bounded ports redact exceptions and terminate timed out helpers" do
    Process.flag(:trap_exit, true)
    assert :ok = RecoveryPort.call({Ports, :ok}, :call, [], 20)
    assert {:error, :port_failed} = RecoveryPort.call({Ports, :crash}, :call, [], 20)
    started = System.monotonic_time(:millisecond)
    assert {:error, :timed_out} = RecoveryPort.call({Ports, :slow}, :call, [], 10)
    assert System.monotonic_time(:millisecond) - started < 100
    refute_receive {:EXIT, _, _}, 10
    refute_receive {:DOWN, _, _, _, _}, 10
  end

  test "one monitored session returns correlated bounded pages" do
    {:ok, session} = RecoveryPort.open_session()
    jobs = List.duplicate({{Ports, :ok}, :call, []}, 128)
    assert {:ok, results, session} = RecoveryPort.page(session, jobs, 100)
    assert results == List.duplicate(:ok, 128)

    stats = RecoveryPort.session_stats(session)
    assert stats.jobs_sent == 128
    assert stats.messages_received == 1
    assert stats.messages_sent == 1
    assert stats.pages_received == 1
    assert stats.pages_sent == 1
    assert stats.results_received == 128
    assert stats.request_bytes > 0
    assert stats.result_bytes > 0
    assert [duration] = stats.page_durations_ms
    assert duration >= 0

    stopped = RecoveryPort.close_session(session)
    refute stopped.alive
    refute_receive {:EXIT, _, _}, 10
    refute_receive {:DOWN, _, _, _, _}, 10
  end

  test "session rejects oversized and malformed pages and remembers terminal failure" do
    {:ok, oversized} = RecoveryPort.open_session()
    jobs = List.duplicate({{Ports, :ok}, :call, []}, 129)
    assert {:error, :invalid_page, oversized} = RecoveryPort.page(oversized, jobs, 100)
    refute oversized.alive
    assert {:error, :invalid_page, ^oversized} = RecoveryPort.page(oversized, [], 100)

    {:ok, malformed} = RecoveryPort.open_session()
    send(self(), {malformed.token, :page_result, 1, [{7, :ok}]})

    assert {:error, :malformed_reply, malformed} =
             RecoveryPort.page(malformed, [{{Ports, :ok}, :call, []}], 100)

    refute malformed.alive
    refute_receive {:EXIT, _, _}, 10
    refute_receive {:DOWN, _, _, _, _}, 10
  end

  test "session rejects missing, duplicate, and out-of-order result correlation" do
    malformed_results = [[], [{0, :ok}, {0, :ok}], [{1, :ok}, {0, :ok}]]

    for results <- malformed_results do
      {:ok, session} = RecoveryPort.open_session()
      send(self(), {session.token, :page_result, 1, results})

      jobs = List.duplicate({{Ports, :ok}, :call, []}, max(length(results), 1))
      assert {:error, :malformed_reply, stopped} = RecoveryPort.page(session, jobs, 100)
      refute stopped.alive
    end

    refute_receive {:EXIT, _, _}, 10
    refute_receive {:DOWN, _, _, _, _}, 10
  end

  test "failure and exit stay per-result without terminating the session" do
    {:ok, session} = RecoveryPort.open_session()

    jobs = [
      {{Ports, :ok}, :call, []},
      {{Ports, :crash}, :call, []},
      {{Ports, :exit}, :call, []},
      {{Ports, :ok}, :call, []}
    ]

    assert {:ok, [:ok, {:error, :port_failed}, {:error, :port_failed}, :ok], session} =
             RecoveryPort.page(session, jobs, 100)

    assert session.alive
    RecoveryPort.close_session(session)
  end

  test "a hang at each page position terminates the same worker" do
    for position <- [0, 31, 63] do
      {:ok, session} = RecoveryPort.open_session()

      jobs =
        for index <- 0..63 do
          config = if index == position, do: {:sleep, 100}, else: :ok
          {{Ports, config}, :call, []}
        end

      assert {:error, :timed_out, stopped} = RecoveryPort.page(session, jobs, 10)
      refute stopped.alive
    end

    refute_receive {:EXIT, _, _}, 10
    refute_receive {:DOWN, _, _, _, _}, 10
  end

  test "normal owner exit terminates its session worker" do
    parent = self()

    owner =
      spawn(fn ->
        {:ok, session} = RecoveryPort.open_session()
        send(parent, {:session_worker, session.pid})

        receive do
          :stop -> :ok
        end
      end)

    assert_receive {:session_worker, worker}
    monitor = Process.monitor(worker)
    send(owner, :stop)
    assert_receive {:DOWN, ^monitor, :process, ^worker, _}, 100
  end

  test "session timeout kills one worker and later pages fail without another start" do
    {:ok, session} = RecoveryPort.open_session()
    started = System.monotonic_time(:millisecond)

    assert {:error, :timed_out, timed_out} =
             RecoveryPort.page(session, [{{Ports, :slow}, :call, []}], 10)

    assert System.monotonic_time(:millisecond) - started < 100
    refute timed_out.alive

    assert {:error, :timed_out, ^timed_out} =
             RecoveryPort.page(timed_out, [{{Ports, :ok}, :call, []}], 10)

    refute_receive {:EXIT, _, _}, 10
    refute_receive {:DOWN, _, _, _, _}, 10
  end
end
