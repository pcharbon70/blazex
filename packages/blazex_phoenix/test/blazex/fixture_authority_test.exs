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

    assert {:error, "session-invalid"} =
             FixtureAuthority.authenticate(session["session_id"], "wrong",
               server: server,
               now_ms: 1_050
             )

    assert {:error, "session-invalid"} =
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
end
