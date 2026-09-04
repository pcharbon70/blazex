defmodule BlazeXBrowserPhoenix.ControlPlugTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias BlazeX.Phoenix.BH01.FixtureAuthority

  @endpoint BlazeXBrowserPhoenix.Endpoint
  @control {"x-bh01-test-control", "enabled"}

  setup do
    FixtureAuthority.reset()
    :ok
  end

  test "health is public but test identity controls are loopback and test-only" do
    health = request(:get, "/bh01/health")
    assert health.status == 200
    assert Jason.decode!(health.resp_body)["phase"] == 6

    denied = request(:post, "/bh01/test/session", [], ~s({"identity_id":"operator"}))
    assert denied.status == 400

    session =
      request(
        :post,
        "/bh01/test/session",
        [@control, {"origin", "http://www.example.com:80"}],
        ~s({"identity_id":"operator"})
      )

    assert session.status == 201
    body = Jason.decode!(session.resp_body)
    assert body["identity_id"] == "operator"
    assert is_binary(body["csrf_token"])
    refute session.resp_body =~ "allowed_actions"
    assert get_resp_header(session, "set-cookie") |> hd() =~ "_blazex_bh01_phase6="
    assert get_resp_header(session, "set-cookie") |> hd() =~ "HttpOnly"
    assert get_resp_header(session, "set-cookie") |> hd() =~ "SameSite=Strict"
  end

  test "test reset and snapshot expose no session or CSRF values" do
    assert request(:post, "/bh01/test/reset", [@control]).status == 200
    snapshot = request(:get, "/bh01/test/state", [@control])
    assert snapshot.status == 200
    assert Jason.decode!(snapshot.resp_body)["active_sessions"] == 0
    refute snapshot.resp_body =~ "csrf"
    refute snapshot.resp_body =~ "session_id"
  end

  test "operator command crosses the cookie and CSRF boundary exactly once" do
    session = establish("operator")
    command = command("browser-one", "request-one", 0)

    accepted = command_request(session, command)
    assert accepted.status == 200

    assert Jason.decode!(accepted.resp_body) == %{
             "protocol" => "blazex.bh01.server-result/0.1",
             "status" => "ok",
             "correlation_id" => "browser-one",
             "result" => %{
               "resource_id" => "counter",
               "value" => 1,
               "version" => 1,
               "replayed" => false
             }
           }

    replay = command_request(session, command)
    assert replay.status == 200
    assert Jason.decode!(replay.resp_body)["result"]["replayed"]

    snapshot = FixtureAuthority.snapshot()
    assert snapshot["resource"]["value"] == 1
    assert Enum.map(snapshot["audit"], & &1["correlation_id"]) == ["browser-one", "browser-one"]
    refute accepted.resp_body =~ session.csrf
    refute inspect(snapshot) =~ session.cookie
  end

  test "anonymous, unauthorized, expired, stale, conflicting, and rate-limited commands do not over-apply" do
    anonymous =
      request(
        :post,
        "/bh01/commands/counter-increment",
        json_headers(),
        Jason.encode!(command("anon", "anon", 0))
      )

    assert anonymous.status == 401
    assert code(anonymous) == "authentication-required"

    viewer = establish("viewer")
    denied = command_request(viewer, command("viewer", "viewer", 0))
    assert denied.status == 403
    assert code(denied) == "authorization-denied"

    operator = establish("operator")
    accepted = command_request(operator, command("accepted", "accepted", 0))
    assert accepted.status == 200

    stale = command_request(operator, command("stale", "stale", 0))
    assert stale.status == 409
    assert code(stale) == "state-stale"

    conflicting =
      command_request(operator, %{
        command("changed", "accepted", 1)
        | "payload" => %{"amount" => 1}
      })

    assert conflicting.status == 409
    assert code(conflicting) == "idempotency-conflict"

    second_stale = command_request(operator, command("stale-two", "stale-two", 0))
    assert second_stale.status == 409
    assert code(second_stale) == "state-stale"

    limited = command_request(operator, command("limited", "limited", 1))
    assert limited.status == 429
    assert code(limited) == "rate-limited"
    assert FixtureAuthority.snapshot()["resource"]["value"] == 1

    expiring = establish("operator")

    assert request(:post, "/bh01/test/expire", [@control, origin(), {"cookie", expiring.cookie}]).status ==
             200

    expired = command_request(expiring, command("expired", "expired", 1))
    assert expired.status == 401
    assert code(expired) == "session-invalid"
  end

  test "transport rejects origin, CSRF, media, malformed, oversized, unknown, and authority hints" do
    session = establish("operator")
    body = Jason.encode!(command("negative", "negative", 0))

    cross_origin =
      request(
        :post,
        "/bh01/commands/counter-increment",
        [
          {"origin", "https://attacker.invalid"},
          {"content-type", "application/json"},
          {"x-bh01-csrf", session.csrf},
          {"cookie", session.cookie}
        ],
        body
      )

    assert cross_origin.status == 403
    assert code(cross_origin) == "origin-invalid"

    invalid_csrf =
      request(
        :post,
        "/bh01/commands/counter-increment",
        [
          origin(),
          {"content-type", "application/json"},
          {"x-bh01-csrf", "incorrect"},
          {"cookie", session.cookie}
        ],
        body
      )

    assert invalid_csrf.status == 403
    assert code(invalid_csrf) == "csrf-invalid"

    assert request(:post, "/bh01/commands/counter-increment", [origin()], body).status == 415

    malformed = command_request(session, "{")
    assert malformed.status == 400
    assert code(malformed) == "command-json-invalid"

    oversized = command_request(session, String.duplicate("x", 2_049))
    assert oversized.status == 413
    assert code(oversized) == "command-oversized"

    hinted = command("hinted", "hinted", 0) |> Map.put("role", "operator")
    assert command_request(session, hinted).status == 422

    unknown = request(:post, "/bh01/commands/delete", json_headers(session), body)
    assert unknown.status == 404
    assert code(unknown) == "command-unknown"
    assert FixtureAuthority.snapshot()["resource"]["value"] == 0
  end

  test "test-only transaction and server failure controls are redacted and effect-free" do
    session = establish("operator")

    transaction =
      command_request(session, command("transaction", "transaction", 0), [
        {"x-bh01-failure-mode", "transaction-error"}
      ])

    assert transaction.status == 500
    assert code(transaction) == "transaction-failed"

    unavailable =
      command_request(session, command("unavailable", "unavailable", 0), [
        {"x-bh01-failure-mode", "server-error"}
      ])

    assert unavailable.status == 503
    assert code(unavailable) == "server-unavailable"
    assert Jason.decode!(unavailable.resp_body)["error"]["retryable"]

    snapshot = FixtureAuthority.snapshot()
    assert snapshot["resource"]["value"] == 0
    refute inspect(snapshot) =~ session.csrf
    refute inspect(snapshot) =~ session.cookie
  end

  defp request(method, path, headers \\ [], body \\ "") do
    headers
    |> Enum.reduce(conn(method, path, body), fn {name, value}, acc ->
      put_req_header(acc, name, value)
    end)
    |> Map.put(:remote_ip, {127, 0, 0, 1})
    |> @endpoint.call(@endpoint.init([]))
  end

  defp establish(identity_id) do
    response =
      request(
        :post,
        "/bh01/test/session",
        [@control, origin()],
        Jason.encode!(%{"identity_id" => identity_id})
      )

    assert response.status == 201
    body = Jason.decode!(response.resp_body)

    cookie =
      response |> get_resp_header("set-cookie") |> hd() |> String.split(";", parts: 2) |> hd()

    %{csrf: body["csrf_token"], cookie: cookie, identity_id: body["identity_id"]}
  end

  defp command_request(session, body, extra_headers \\ []) do
    encoded = if is_map(body), do: Jason.encode!(body), else: body

    request(
      :post,
      "/bh01/commands/counter-increment",
      json_headers(session) ++ [@control] ++ extra_headers,
      encoded
    )
  end

  defp json_headers(session \\ nil) do
    base = [origin(), {"content-type", "application/json"}]

    if session,
      do: base ++ [{"x-bh01-csrf", session.csrf}, {"cookie", session.cookie}],
      else: base
  end

  defp origin, do: {"origin", "http://www.example.com:80"}
  defp code(conn), do: Jason.decode!(conn.resp_body)["error"]["code"]

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
