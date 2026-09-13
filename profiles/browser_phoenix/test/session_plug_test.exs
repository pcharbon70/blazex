defmodule BlazeXBrowserPhoenix.SessionPlugTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias BlazeX.Phoenix.SessionRegistry

  @endpoint BlazeXBrowserPhoenix.Endpoint
  @control {"x-bh07-test-control", "enabled"}
  @origin {"origin", "http://www.example.com:80"}

  setup do
    SessionRegistry.reset()
    :ok
  end

  test "anonymous projection is public, bounded, and non-authoritative" do
    response = request(:get, "/bh07/session")
    assert response.status == 200

    assert Jason.decode!(response.resp_body) == %{
             "protocol" => "blazex.bh07.session/1",
             "state" => "anonymous"
           }

    assert get_resp_header(response, "cache-control") == ["no-store"]
    assert get_resp_header(response, "content-type") == ["application/json"]
    refute response.resp_body =~ "session_id"
    refute response.resp_body =~ "role"
    refute response.resp_body =~ "permission"
  end

  test "test-only issuance stores the opaque id only in an encrypted strict cookie" do
    response = issue("operator")
    assert response.status == 201
    assert Jason.decode!(response.resp_body)["subject"] == "Operator"
    refute response.resp_body =~ "session_id"
    refute response.resp_body =~ "operator"
    refute response.resp_body =~ "role"
    [set_cookie] = get_resp_header(response, "set-cookie")
    assert set_cookie =~ "_blazex_browser_phoenix="
    assert set_cookie =~ "HttpOnly"
    assert set_cookie =~ "SameSite=Strict"
    cookie = cookie(set_cookie)

    current = request(:get, "/bh07/session", [{"cookie", cookie}])
    assert current.status == 200
    assert Jason.decode!(current.resp_body)["state"] == "authenticated"
    assert Jason.decode!(current.resp_body)["subject"] == "Operator"
    refute current.resp_body =~ "session_id"
  end

  test "issuance is loopback, same-origin, header-gated, typed, and bounded" do
    body = Jason.encode!(%{"identity_id" => "operator"})
    assert request(:post, "/bh07/test/session", [@origin, json()], body).status == 404
    assert request(:post, "/bh07/test/session", [@control, json()], body).status == 404
    assert request(:post, "/bh07/test/session", [@control, @origin], body).status == 404
    assert request(:post, "/bh07/test/session", [@control, @origin, json()], "{").status == 404
    assert issue("unknown").status == 404

    hinted = Jason.encode!(%{"identity_id" => "operator", "role" => "administrator"})
    assert request(:post, "/bh07/test/session", [@control, @origin, json()], hinted).status == 404

    oversized = Jason.encode!(%{"identity_id" => String.duplicate("x", 129)})

    assert request(:post, "/bh07/test/session", [@control, @origin, json()], oversized).status ==
             404

    assert SessionRegistry.snapshot()["active_sessions"] == 0
  end

  test "replacement and reset retain one session and invalidate the prior cookie" do
    first = issue("operator")
    first_cookie = cookie(hd(get_resp_header(first, "set-cookie")))
    second = issue("viewer", [{"cookie", first_cookie}])
    second_cookie = cookie(hd(get_resp_header(second, "set-cookie")))
    assert SessionRegistry.snapshot()["active_sessions"] == 1

    assert Jason.decode!(request(:get, "/bh07/session", [{"cookie", first_cookie}]).resp_body)[
             "state"
           ] == "anonymous"

    assert Jason.decode!(request(:get, "/bh07/session", [{"cookie", second_cookie}]).resp_body)[
             "subject"
           ] == "Viewer"

    reset = request(:post, "/bh07/test/reset", [@control, @origin, {"cookie", second_cookie}])
    assert reset.status == 200
    assert SessionRegistry.snapshot()["active_sessions"] == 0
  end

  test "logout is same-origin, idempotent, and invalidates server state" do
    issued = issue("operator")
    cookie = cookie(hd(get_resp_header(issued, "set-cookie")))
    assert request(:delete, "/bh07/session", [{"cookie", cookie}]).status == 403

    logout = request(:delete, "/bh07/session", [@origin, {"cookie", cookie}])
    assert logout.status == 200
    assert Jason.decode!(logout.resp_body)["state"] == "anonymous"
    assert SessionRegistry.snapshot()["active_sessions"] == 0
    assert request(:delete, "/bh07/session", [@origin]).status == 200
    assert request(:post, "/bh07/session").status == 405
  end

  defp issue(identity, extra_headers \\ []) do
    request(
      :post,
      "/bh07/test/session",
      [@control, @origin, json() | extra_headers],
      Jason.encode!(%{"identity_id" => identity})
    )
  end

  defp request(method, path, headers \\ [], body \\ "") do
    conn =
      Enum.reduce(headers, conn(method, path, body), fn {name, value}, acc ->
        put_req_header(acc, name, value)
      end)

    @endpoint.call(conn, @endpoint.init([]))
  end

  defp json, do: {"content-type", "application/json"}
  defp cookie(set_cookie), do: set_cookie |> String.split(";", parts: 2) |> hd()
end
