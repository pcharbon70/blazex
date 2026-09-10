defmodule BlazeX.RecoveryPolicyTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{RecoveryPolicy, RecoveryPort}

  defmodule Ports do
    def call(:slow), do: Process.sleep(100)
    def call(:ok), do: :ok
    def call(:crash), do: raise("private")
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
end
