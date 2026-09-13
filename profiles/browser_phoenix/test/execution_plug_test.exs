defmodule BlazeXBrowserPhoenix.ExecutionPlugTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias BlazeX.Phoenix.{CommandAdmission, CommandExecution, SessionRegistry}
  alias BlazeX.Phoenix.BH01.FixtureAuthority

  @endpoint BlazeXBrowserPhoenix.Endpoint
  @control {"x-bh07-test-control", "enabled"}
  @origin {"origin", "http://www.example.com:80"}

  setup do
    SessionRegistry.reset()
    CommandAdmission.reset()
    CommandExecution.reset()
    FixtureAuthority.reset()
    :ok
  end

  test "authorized operator executes once and exact replay returns the first result" do
    session = establish("operator")
    envelope = command("execute", "execute-key", 0, 3)

    first = execute(session, envelope)
    assert first.status == 200
    assert get_resp_header(first, "cache-control") == ["no-store"]
    assert get_resp_header(first, "x-content-type-options") == ["nosniff"]

    assert Jason.decode!(first.resp_body) == %{
             "protocol" => "blazex.bh07.command-result/1",
             "status" => "ok",
             "correlation_id" => "execute",
             "result" => %{
               "resource_id" => "counter",
               "value" => 3,
               "revision" => 1,
               "replayed" => false,
               "executed" => true
             }
           }

    replay = execute(session, envelope)
    assert replay.status == 200
    assert Jason.decode!(replay.resp_body)["result"]["replayed"]
    assert CommandExecution.snapshot()["resource"]["value"] == 3
    assert FixtureAuthority.snapshot()["resource"]["value"] == 0
    refute first.resp_body =~ session.csrf
    refute first.resp_body =~ "operator"
  end

  test "viewer and stale revision cannot mutate" do
    viewer = establish("viewer")
    denied = execute(viewer, command("viewer", "viewer-key", 0, 1))
    assert denied.status == 403
    assert code(denied) == "authorization-denied"

    operator = establish("operator")
    stale = execute(operator, command("stale", "stale-key", 7, 1))
    assert stale.status == 409
    assert code(stale) == "state-stale"
    assert CommandExecution.snapshot()["resource"]["value"] == 0
  end

  test "changed idempotency request conflicts without duplicate mutation" do
    session = establish("operator")
    original = command("original", "shared-key", 0, 1)
    assert execute(session, original).status == 200

    changed = %{original | "correlation_id" => "changed", "expected_revision" => 1}
    conflict = execute(session, changed)
    assert conflict.status == 409
    assert code(conflict) == "idempotency-conflict"
    assert CommandExecution.snapshot()["resource"]["value"] == 1
  end

  test "authentication, origin, and current CSRF are required" do
    envelope = command("security", "security-key", 0, 1)

    anonymous =
      request(:post, "/bh07/commands/execute", [@origin, json()], Jason.encode!(envelope))

    assert anonymous.status == 401
    assert code(anonymous) == "authentication-required"

    session = establish("operator")
    cross_origin = execute(session, envelope, origin: "https://attacker.invalid")
    assert cross_origin.status == 403
    assert code(cross_origin) == "origin-invalid"

    wrong = execute(%{session | csrf: String.duplicate("x", 43)}, envelope)
    assert wrong.status == 403
    assert code(wrong) == "csrf-invalid"
    assert CommandExecution.snapshot()["resource"]["value"] == 0
  end

  test "transport rejects invalid media, JSON, size, method, and operation" do
    session = establish("operator")
    encoded = Jason.encode!(command("transport", "transport-key", 0, 1))
    base = [@origin, {"cookie", session.cookie}, {"x-blazex-csrf", session.csrf}]

    assert request(:post, "/bh07/commands/execute", base, encoded).status == 415

    assert code(request(:post, "/bh07/commands/execute", [json() | base], "{")) ==
             "command-json-invalid"

    oversized =
      request(:post, "/bh07/commands/execute", [json() | base], String.duplicate("x", 2_049))

    assert oversized.status == 413
    assert code(oversized) == "command-oversized"
    assert request(:get, "/bh07/commands/execute").status == 405

    invalid = command("payload", "payload-key", 0, 11)
    assert code(execute(session, invalid)) == "command-payload-invalid"
    assert CommandExecution.snapshot()["resource"]["value"] == 0
  end

  test "logout releases execution records but preserves authoritative resource" do
    session = establish("operator")
    assert execute(session, command("logout", "logout-key", 0, 1)).status == 200

    logout =
      request(:delete, "/bh07/session", [
        @origin,
        {"cookie", session.cookie},
        {"x-blazex-csrf", session.csrf}
      ])

    assert logout.status == 200
    assert CommandExecution.snapshot()["executions"] == 0
    assert CommandExecution.snapshot()["tracked_sessions"] == 0
    assert CommandExecution.snapshot()["resource"]["value"] == 1
  end

  test "gated reset clears sessions, admissions, execution state, and audit" do
    session = establish("operator")
    assert execute(session, command("reset", "reset-key", 0, 1)).status == 200

    reset = request(:post, "/bh07/test/reset", [@control, @origin, {"cookie", session.cookie}])
    assert reset.status == 200
    assert SessionRegistry.snapshot()["active_sessions"] == 0
    assert CommandAdmission.snapshot()["admissions"] == 0

    assert %{"executions" => 0, "resource" => %{"value" => 0}, "audit" => []} =
             CommandExecution.snapshot()
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

  defp execute(session, envelope, options \\ []) do
    origin = Keyword.get(options, :origin, elem(@origin, 1))

    request(
      :post,
      "/bh07/commands/execute",
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

  defp command(correlation, idempotency, expected_revision, amount) do
    %{
      "protocol" => "blazex.bh07.command-intent/1",
      "command" => "counter.increment",
      "schema" => "counter.increment",
      "correlation_id" => correlation,
      "idempotency_key" => idempotency,
      "expected_revision" => expected_revision,
      "payload" => %{"amount" => amount}
    }
  end

  defp json, do: {"content-type", "application/json"}
  defp cookie(set_cookie), do: set_cookie |> String.split(";", parts: 2) |> hd()
  defp code(conn), do: Jason.decode!(conn.resp_body)["error"]["code"]
end
