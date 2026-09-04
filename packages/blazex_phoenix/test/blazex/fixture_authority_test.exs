defmodule BlazeX.Phoenix.BH01.FixtureAuthorityTest do
  use ExUnit.Case, async: true

  alias BlazeX.Phoenix.BH01.FixtureAuthority

  setup do
    name = Module.concat(__MODULE__, "Server#{System.unique_integer([:positive])}")
    start_supervised!({FixtureAuthority, name: name})
    %{server: name}
  end

  test "issues opaque sessions while keeping roles and state on the server", %{server: server} do
    assert {:ok, session} =
             FixtureAuthority.issue_session("operator",
               server: server,
               now_ms: 1_000,
               ttl_ms: 500
             )

    assert session["identity_id"] == "operator"
    assert is_binary(session["session_id"])
    assert is_binary(session["csrf_token"])
    refute Map.has_key?(session, "role")
    refute Map.has_key?(session, "allowed_actions")

    assert {:ok, context} =
             FixtureAuthority.authenticate(session["session_id"], session["csrf_token"],
               server: server,
               now_ms: 1_100
             )

    assert context.role == "operator"
    assert context.allowed_actions == ["counter.increment"]

    snapshot = FixtureAuthority.snapshot(server)
    assert snapshot["active_sessions"] == 1
    refute inspect(snapshot) =~ session["csrf_token"]
    refute inspect(snapshot) =~ session["session_id"]
  end

  test "rejects expired, revoked, disabled, unknown, and incorrect-CSRF sessions", %{
    server: server
  } do
    assert {:error, "identity-disabled"} =
             FixtureAuthority.issue_session("disabled", server: server)

    assert {:error, "identity-unknown"} =
             FixtureAuthority.issue_session("missing", server: server)

    assert {:ok, session} =
             FixtureAuthority.issue_session("viewer", server: server, now_ms: 1_000, ttl_ms: 100)

    assert {:error, "csrf-invalid"} =
             FixtureAuthority.authenticate(session["session_id"], "wrong",
               server: server,
               now_ms: 1_050
             )

    assert {:error, "session-expired"} =
             FixtureAuthority.authenticate(session["session_id"], session["csrf_token"],
               server: server,
               now_ms: 1_100
             )

    assert :ok = FixtureAuthority.expire_session(session["session_id"], server)

    assert {:error, "session-invalid"} =
             FixtureAuthority.authenticate(session["session_id"], session["csrf_token"],
               server: server,
               now_ms: 1_050
             )
  end

  test "reset restores authoritative data without exposing session records", %{server: server} do
    assert {:ok, _session} = FixtureAuthority.issue_session("operator", server: server)
    assert %{"reset_generation" => 2, "active_sessions" => 0} = FixtureAuthority.reset(server)

    assert %{"resource" => %{"id" => "counter", "value" => 0, "version" => 0}} =
             FixtureAuthority.snapshot(server)
  end

  test "authorized command applies once and exact replay returns the original outcome", %{
    server: server
  } do
    session = session(server, "operator")
    command = command("correlation-one", "idempotency-one", 0)

    assert {:ok,
            %{
              "status" => "ok",
              "result" => %{"value" => 1, "version" => 1, "replayed" => false}
            }} = execute(server, session, command)

    assert {:ok, %{"result" => %{"value" => 1, "version" => 1, "replayed" => true}}} =
             execute(server, session, command)

    snapshot = FixtureAuthority.snapshot(server)
    assert snapshot["resource"] == %{"id" => "counter", "value" => 1, "version" => 1}
    assert snapshot["idempotency_count"] == 1
    assert Enum.map(snapshot["audit"], & &1["outcome"]) == ["accepted", "replayed"]

    refute inspect(snapshot) =~ session["session_id"]
    refute inspect(snapshot) =~ session["csrf_token"]
    refute inspect(snapshot) =~ "idempotency-one"
  end

  test "server-owned identity and current state deny unauthorized and stale commands", %{
    server: server
  } do
    viewer = session(server, "viewer")

    assert {:error, %{"error" => %{"code" => "authorization-denied"}}} =
             execute(server, viewer, command("viewer-denied", "viewer-key", 0))

    operator = session(server, "operator")

    assert {:ok, _} =
             execute(server, operator, command("operator-ok", "operator-key", 0))

    assert {:error, %{"error" => %{"code" => "state-stale"}}} =
             execute(server, operator, command("operator-stale", "stale-key", 0))

    assert FixtureAuthority.snapshot(server)["resource"]["value"] == 1
  end

  test "malformed, unknown, conflicting, expired, and incorrect-CSRF requests have no effect", %{
    server: server
  } do
    session = session(server, "operator", now_ms: 1_000, ttl_ms: 100)

    assert {:error, %{"error" => %{"code" => "command-invalid"}}} =
             execute(server, session, Map.delete(command("bad", "bad-key", 0), "payload"),
               now_ms: 1_050
             )

    assert {:error, %{"error" => %{"code" => "command-unknown"}}} =
             execute(
               server,
               session,
               %{command("unknown", "unknown-key", 0) | "command" => "counter.delete"},
               now_ms: 1_050
             )

    assert {:error, %{"error" => %{"code" => "csrf-invalid"}}} =
             FixtureAuthority.execute(
               session["session_id"],
               "incorrect",
               command("csrf", "csrf-key", 0),
               server: server,
               now_ms: 1_050
             )

    assert {:error, %{"error" => %{"code" => "session-expired"}}} =
             execute(server, session, command("expired", "expired-key", 0), now_ms: 1_100)

    fresh = session(server, "operator")
    original = command("conflict", "same-key", 0)
    assert {:ok, _} = execute(server, fresh, original)

    changed = %{original | "correlation_id" => "conflict-changed"}

    assert {:error, %{"error" => %{"code" => "idempotency-conflict"}}} =
             execute(server, fresh, changed)

    assert FixtureAuthority.snapshot(server)["resource"]["value"] == 1
  end

  test "rate and test-controlled failures are bounded and never mutate", %{server: server} do
    session = session(server, "operator")

    assert {:error, %{"error" => %{"code" => "transaction-failed", "retryable" => true}}} =
             execute(server, session, command("transaction", "failure-one", 0),
               failure_mode: :transaction_error
             )

    assert {:error, %{"error" => %{"code" => "server-unavailable", "retryable" => true}}} =
             execute(server, session, command("server", "failure-two", 0),
               failure_mode: :server_error
             )

    assert {:error, %{"error" => %{"code" => "state-stale"}}} =
             execute(server, session, command("stale", "failure-three", 9))

    assert {:error, %{"error" => %{"code" => "rate-limited"}}} =
             execute(server, session, command("limited", "failure-four", 0))

    assert FixtureAuthority.snapshot(server)["resource"]["value"] == 0
  end

  defp session(server, identity, options \\ []) do
    assert {:ok, value} =
             FixtureAuthority.issue_session(identity, Keyword.put(options, :server, server))

    value
  end

  defp execute(server, session, command, options \\ []) do
    FixtureAuthority.execute(
      session["session_id"],
      session["csrf_token"],
      command,
      Keyword.put(options, :server, server)
    )
  end

  defp command(correlation_id, idempotency_key, expected_version) do
    %{
      "protocol" => "blazex.bh01.server-command/0.1",
      "command" => "counter.increment",
      "correlation_id" => correlation_id,
      "idempotency_key" => idempotency_key,
      "resource_id" => "counter",
      "expected_version" => expected_version,
      "payload" => %{"amount" => 1}
    }
  end
end
