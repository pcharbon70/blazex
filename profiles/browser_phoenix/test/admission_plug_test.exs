defmodule BlazeXBrowserPhoenix.AdmissionPlugTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias BlazeX.Phoenix.{CommandAdmission, SessionRegistry}
  alias BlazeX.Phoenix.BH01.FixtureAuthority

  @endpoint BlazeXBrowserPhoenix.Endpoint
  @control {"x-bh07-test-control", "enabled"}
  @origin {"origin", "http://www.example.com:80"}

  setup do
    SessionRegistry.reset()
    CommandAdmission.reset()
    FixtureAuthority.reset()
    :ok
  end

  test "authorized intent returns an idempotent non-executing receipt" do
    session = establish("operator")
    envelope = command("accepted", "accepted-key")
    first = admit(session, envelope)
    assert first.status == 202
    assert get_resp_header(first, "cache-control") == ["no-store"]
    assert get_resp_header(first, "x-content-type-options") == ["nosniff"]

    assert get_resp_header(first, "content-length") == [
             Integer.to_string(byte_size(first.resp_body))
           ]

    assert Jason.decode!(first.resp_body) == %{
             "protocol" => "blazex.bh07.command-admission/1",
             "status" => "admitted",
             "correlation_id" => "accepted",
             "receipt" => %{
               "command" => "counter.increment",
               "schema" => "counter.increment",
               "expected_revision" => 0,
               "replayed" => false,
               "executed" => false
             }
           }

    replay = admit(session, envelope)
    assert replay.status == 202
    assert Jason.decode!(replay.resp_body)["receipt"]["replayed"]
    assert CommandAdmission.snapshot()["admissions"] == 1
    assert CommandAdmission.snapshot()["executed"] == 0
    assert FixtureAuthority.snapshot()["resource"]["value"] == 0
    refute first.resp_body =~ "operator"
    refute first.resp_body =~ session.csrf
    refute first.resp_body =~ "allowed_actions"
  end

  test "server-owned subject grant denies a viewer" do
    viewer = establish("viewer")
    denied = admit(viewer, command("viewer", "viewer-key"))
    assert denied.status == 403
    assert code(denied) == "authorization-denied"
    assert CommandAdmission.snapshot()["admissions"] == 0
  end

  test "unknown, schema-invalid, payload-invalid, and authority-hinted inputs fail" do
    session = establish("operator")

    unknown = %{command("unknown", "unknown") | "command" => "counter.delete"}
    assert code(admit(session, unknown)) == "command-unknown"

    wrong_schema = %{command("schema", "schema") | "schema" => "counter.other"}
    assert code(admit(session, wrong_schema)) == "command-schema-invalid"

    wrong_payload = %{command("payload", "payload") | "payload" => %{"amount" => 99}}
    assert code(admit(session, wrong_payload)) == "command-payload-invalid"

    hinted = command("hint", "hint") |> Map.put("subject", "operator")
    assert code(admit(session, hinted)) == "command-invalid"
    assert CommandAdmission.snapshot()["admissions"] == 0
  end

  test "authentication, origin, and current CSRF proof are all required" do
    envelope = command("security", "security")
    anonymous = request(:post, "/bh07/commands/admit", [@origin, json()], Jason.encode!(envelope))
    assert anonymous.status == 401
    assert code(anonymous) == "authentication-required"

    session = establish("operator")
    cross_origin = admit(session, envelope, origin: "https://attacker.invalid")
    assert cross_origin.status == 403
    assert code(cross_origin) == "origin-invalid"

    wrong_csrf = admit(%{session | csrf: String.duplicate("x", 43)}, envelope)
    assert wrong_csrf.status == 403
    assert code(wrong_csrf) == "csrf-invalid"
    assert CommandAdmission.snapshot()["admissions"] == 0
  end

  test "transport rejects media, malformed, oversized, method, and unknown route" do
    session = establish("operator")
    encoded = Jason.encode!(command("transport", "transport"))
    base = [@origin, {"cookie", session.cookie}, {"x-blazex-csrf", session.csrf}]

    assert request(:post, "/bh07/commands/admit", base, encoded).status == 415

    assert code(request(:post, "/bh07/commands/admit", [json() | base], "{")) ==
             "command-json-invalid"

    oversized =
      request(:post, "/bh07/commands/admit", [json() | base], String.duplicate("x", 2_049))

    assert oversized.status == 413
    assert code(oversized) == "command-oversized"
    assert request(:get, "/bh07/commands/admit").status == 405
    assert request(:post, "/bh07/commands/other").status == 404
  end

  test "changed idempotency request conflicts without a second admission" do
    session = establish("operator")
    assert admit(session, command("first", "same-key")).status == 202
    changed = %{command("changed", "same-key") | "expected_revision" => 1}
    conflict = admit(session, changed)
    assert conflict.status == 409
    assert code(conflict) == "idempotency-conflict"
    assert CommandAdmission.snapshot()["admissions"] == 1
  end

  test "per-session admission bound rejects unique work but permits exact replay" do
    session = establish("operator")

    for index <- 1..32 do
      assert admit(session, command("rate-#{index}", "rate-#{index}")).status == 202
    end

    limited = admit(session, command("rate-33", "rate-33"))
    assert limited.status == 429
    assert code(limited) == "admission-rate-limited"
    assert admit(session, command("rate-1", "rate-1")).status == 202
    assert CommandAdmission.snapshot()["admissions"] == 32
  end

  test "gated BH-07 reset clears session and admission authority together" do
    session = establish("operator")
    assert admit(session, command("reset", "reset")).status == 202

    reset =
      request(:post, "/bh07/test/reset", [@control, @origin, {"cookie", session.cookie}])

    assert reset.status == 200
    assert SessionRegistry.snapshot()["active_sessions"] == 0
    assert CommandAdmission.snapshot()["admissions"] == 0
  end

  test "session logout releases private admission records" do
    session = establish("operator")
    assert admit(session, command("logout", "logout")).status == 202

    logout =
      request(:delete, "/bh07/session", [
        @origin,
        {"cookie", session.cookie},
        {"x-blazex-csrf", session.csrf}
      ])

    assert logout.status == 200
    assert CommandAdmission.snapshot()["admissions"] == 0
    assert CommandAdmission.snapshot()["tracked_sessions"] == 0
  end

  defp establish(identity) do
    response =
      request(
        :post,
        "/bh07/test/session",
        [@control, @origin, json()],
        Jason.encode!(%{"identity_id" => identity})
      )

    assert response.status == 201
    body = Jason.decode!(response.resp_body)
    cookie = response |> get_resp_header("set-cookie") |> hd() |> cookie()
    %{cookie: cookie, csrf: body["csrf_token"]}
  end

  defp admit(session, envelope, options \\ []) do
    origin = Keyword.get(options, :origin, elem(@origin, 1))

    request(
      :post,
      "/bh07/commands/admit",
      [{"origin", origin}, json(), {"cookie", session.cookie}, {"x-blazex-csrf", session.csrf}],
      Jason.encode!(envelope)
    )
  end

  defp request(method, path, headers \\ [], body \\ "") do
    conn =
      Enum.reduce(headers, conn(method, path, body), fn {name, value}, acc ->
        put_req_header(acc, name, value)
      end)

    @endpoint.call(conn, @endpoint.init([]))
  end

  defp command(correlation, idempotency) do
    %{
      "protocol" => "blazex.bh07.command-intent/1",
      "command" => "counter.increment",
      "schema" => "counter.increment",
      "correlation_id" => correlation,
      "idempotency_key" => idempotency,
      "expected_revision" => 0,
      "payload" => %{"amount" => 1}
    }
  end

  defp json, do: {"content-type", "application/json"}
  defp cookie(set_cookie), do: set_cookie |> String.split(";", parts: 2) |> hd()
  defp code(conn), do: Jason.decode!(conn.resp_body)["error"]["code"]
end
