defmodule BlazeX.Phoenix.SessionRegistryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias BlazeX.Phoenix.SessionRegistry

  setup do
    name = Module.concat(__MODULE__, "Registry#{System.unique_integer([:positive])}")
    start_supervised!({SessionRegistry, name: name, max_sessions: 2})
    %{server: name}
  end

  test "issues opaque identifiers and returns only a redacted projection", %{server: server} do
    assert {:ok, issued} =
             SessionRegistry.issue("subject-1", "Ada", server: server, now_ms: 1_000, ttl_ms: 500)

    assert byte_size(issued["session_id"]) == 43
    refute issued["projection"] |> Map.has_key?("session_id")
    refute inspect(issued["projection"]) =~ "role"
    refute inspect(issued["projection"]) =~ "permission"

    assert {:ok,
            %{
              "protocol" => "blazex.bh07.session/1",
              "state" => "authenticated",
              "subject" => "Ada",
              "expires_at_ms" => 1_500
            }} = SessionRegistry.lookup(issued["session_id"], server: server, now_ms: 1_499)

    refute inspect(SessionRegistry.snapshot(server)) =~ issued["session_id"]
  end

  test "expires and prunes before enforcing capacity", %{server: server} do
    first = issue(server, "first", now_ms: 0, ttl_ms: 10)
    _second = issue(server, "second", now_ms: 0, ttl_ms: 20)

    assert {:error, "session-capacity"} =
             SessionRegistry.issue("third", "Third", server: server, now_ms: 1)

    assert {:error, "session-invalid"} = SessionRegistry.lookup(first, server: server, now_ms: 10)
    assert {:ok, _issued} = SessionRegistry.issue("third", "Third", server: server, now_ms: 10)
    assert SessionRegistry.snapshot(server)["active_sessions"] == 2
  end

  test "rotation atomically invalidates the prior identifier without extending expiry", %{
    server: server
  } do
    old = issue(server, "rotate", now_ms: 1_000, ttl_ms: 500)
    assert {:ok, rotated} = SessionRegistry.rotate(old, server: server, now_ms: 1_100)
    refute rotated["session_id"] == old
    assert rotated["projection"]["expires_at_ms"] == 1_500

    assert {:error, "session-invalid"} =
             SessionRegistry.lookup(old, server: server, now_ms: 1_100)

    assert {:ok, _projection} =
             SessionRegistry.lookup(rotated["session_id"], server: server, now_ms: 1_100)

    assert SessionRegistry.snapshot(server)["active_sessions"] == 1
  end

  test "revocation is idempotent", %{server: server} do
    session_id = issue(server, "revoke")
    assert :ok = SessionRegistry.revoke(session_id, server)
    assert :ok = SessionRegistry.revoke(session_id, server)
    assert :ok = SessionRegistry.revoke("malformed", server)
    assert {:error, "session-invalid"} = SessionRegistry.lookup(session_id, server: server)
  end

  test "concurrent issuance never exceeds capacity", %{server: server} do
    results =
      1..20
      |> Task.async_stream(
        fn index ->
          SessionRegistry.issue("subject-#{index}", "Subject #{index}", server: server)
        end,
        max_concurrency: 20,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.count(results, &match?({:ok, _}, &1)) == 2
    assert Enum.count(results, &match?({:error, "session-capacity"}, &1)) == 18
    assert SessionRegistry.snapshot(server)["active_sessions"] == 2
  end

  test "rejects invalid subjects and TTLs without allocating", %{server: server} do
    invalid = [
      {"UPPER", "Label", []},
      {:atom, "Label", []},
      {"valid", "", []},
      {"valid", String.duplicate("x", 81), []},
      {"valid", "line\nbreak", []},
      {"valid", "Label", [ttl_ms: 0]},
      {"valid", "Label", [ttl_ms: 3_600_001]}
    ]

    for {subject, label, options} <- invalid do
      assert {:error, _code} =
               SessionRegistry.issue(subject, label, Keyword.put(options, :server, server))
    end

    assert SessionRegistry.snapshot(server)["active_sessions"] == 0
  end

  test "reset and process restart invalidate all identifiers", %{server: server} do
    reset_id = issue(server, "reset")
    assert %{"active_sessions" => 0, "generation" => 2} = SessionRegistry.reset(server)
    assert {:error, "session-invalid"} = SessionRegistry.lookup(reset_id, server: server)

    restart_id = issue(server, "restart")
    original = Process.whereis(server)
    monitor = Process.monitor(original)

    capture_log(fn ->
      Process.exit(original, :kill)
      assert_receive {:DOWN, ^monitor, :process, ^original, :killed}, 1_000
      await_restart(server, original, 100)
    end)

    assert {:error, "session-invalid"} = SessionRegistry.lookup(restart_id, server: server)
    assert SessionRegistry.snapshot(server)["generation"] == 1
  end

  defp issue(server, suffix, options \\ []) do
    subject = "subject-#{suffix}"
    label = "Subject #{suffix}"

    assert {:ok, issued} =
             SessionRegistry.issue(subject, label, Keyword.put(options, :server, server))

    issued["session_id"]
  end

  defp await_restart(_name, _old, 0), do: flunk("session registry did not restart")

  defp await_restart(name, old, attempts) do
    case Process.whereis(name) do
      pid when is_pid(pid) and pid != old ->
        pid

      _ ->
        Process.sleep(5)
        await_restart(name, old, attempts - 1)
    end
  end
end
