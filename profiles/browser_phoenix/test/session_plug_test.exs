defmodule BlazeXBrowserPhoenix.SessionPlugTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias BlazeX.Phoenix.{CommandAdmission, SessionRegistry}

  @endpoint BlazeXBrowserPhoenix.Endpoint
  @control {"x-bh07-test-control", "enabled"}
  @origin {"origin", "http://www.example.com:80"}

  setup do
    SessionRegistry.reset()
    CommandAdmission.reset()
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
    refute response.resp_body =~ "csrf_token"
    refute response.resp_body =~ "role"
    refute response.resp_body =~ "permission"
  end

  test "test-only issuance stores the opaque id only in an encrypted strict cookie" do
    response = issue("operator")
    assert response.status == 201
    body = Jason.decode!(response.resp_body)
    assert body["subject"] == "Operator"
    assert byte_size(body["csrf_token"]) == 43
    refute response.resp_body =~ "session_id"
    refute response.resp_body =~ "operator"
    refute response.resp_body =~ "role"
    [set_cookie] = get_resp_header(response, "set-cookie")
    assert set_cookie =~ "_blazex_browser_phoenix="
    assert set_cookie =~ "HttpOnly"
    assert set_cookie =~ "SameSite=Strict"
    refute set_cookie =~ body["csrf_token"]
    cookie = cookie(set_cookie)

    current = request(:get, "/bh07/session", [{"cookie", cookie}])
    assert current.status == 200
    assert Jason.decode!(current.resp_body)["state"] == "authenticated"
    assert Jason.decode!(current.resp_body)["subject"] == "Operator"
    assert Jason.decode!(current.resp_body)["csrf_token"] == body["csrf_token"]
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

  test "CSRF rotation is same-origin, proof-bound, atomic, and method-explicit" do
    issued = issue("operator")
    cookie = cookie(hd(get_resp_header(issued, "set-cookie")))
    old_token = csrf(issued)

    assert request(:post, "/bh07/csrf/rotate", [{"cookie", cookie}, csrf_header(old_token)]).status ==
             403

    assert request(:post, "/bh07/csrf/rotate", [@origin, {"cookie", cookie}, csrf_header("wrong")]).status ==
             403

    rotated =
      request(:post, "/bh07/csrf/rotate", [@origin, {"cookie", cookie}, csrf_header(old_token)])

    assert rotated.status == 200
    new_token = csrf(rotated)
    refute new_token == old_token
    new_cookie = cookie(hd(get_resp_header(rotated, "set-cookie")))

    assert request(:post, "/bh07/csrf/rotate", [
             @origin,
             {"cookie", cookie},
             csrf_header(old_token)
           ]).status == 403

    assert request(:post, "/bh07/csrf/rotate", [
             @origin,
             {"cookie", new_cookie},
             csrf_header(old_token)
           ]).status ==
             403

    assert csrf(request(:get, "/bh07/session", [{"cookie", new_cookie}])) == new_token
    assert request(:get, "/bh07/csrf/rotate").status == 405
  end

  test "authenticated logout requires same origin and current proof" do
    issued = issue("operator")
    cookie = cookie(hd(get_resp_header(issued, "set-cookie")))
    token = csrf(issued)
    assert request(:delete, "/bh07/session", [{"cookie", cookie}]).status == 403
    assert request(:delete, "/bh07/session", [@origin, {"cookie", cookie}]).status == 403

    logout =
      request(:delete, "/bh07/session", [@origin, {"cookie", cookie}, csrf_header(token)])

    assert logout.status == 200
    assert Jason.decode!(logout.resp_body)["state"] == "anonymous"
    assert SessionRegistry.snapshot()["active_sessions"] == 0
    assert request(:delete, "/bh07/session", [@origin]).status == 200
    assert request(:post, "/bh07/session").status == 405
  end

  test "canonical origin accepts default-port omission and rejects duplicates" do
    body = Jason.encode!(%{"identity_id" => "operator"})

    accepted =
      request(
        :post,
        "/bh07/test/session",
        [@control, {"origin", "http://www.example.com"}, json()],
        body
      )

    assert accepted.status == 201

    duplicate = request_with_duplicate_origin(body)

    assert duplicate.status == 404
  end

  test "legacy BH-01 cookie cleanup cannot erase BH-07 security state" do
    issued = issue("operator")
    original_cookie = cookie(hd(get_resp_header(issued, "set-cookie")))

    cleared =
      request(:delete, "/bh01/test/session", [
        {"x-bh01-test-control", "enabled"},
        @origin,
        {"cookie", original_cookie}
      ])

    assert cleared.status == 200
    preserved_cookie = cookie(hd(get_resp_header(cleared, "set-cookie")))

    assert Jason.decode!(request(:get, "/bh07/session", [{"cookie", preserved_cookie}]).resp_body)[
             "state"
           ] == "authenticated"
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

  defp request_with_duplicate_origin(body) do
    conn =
      conn(:post, "/bh07/test/session", body)
      |> put_req_header(elem(@control, 0), elem(@control, 1))
      |> put_req_header("content-type", "application/json")
      |> Map.update!(:req_headers, fn headers -> [@origin, @origin | headers] end)

    @endpoint.call(conn, @endpoint.init([]))
  end

  defp json, do: {"content-type", "application/json"}
  defp cookie(set_cookie), do: set_cookie |> String.split(";", parts: 2) |> hd()
  defp csrf(response), do: Jason.decode!(response.resp_body)["csrf_token"]
  defp csrf_header(token), do: {"x-blazex-csrf", token}
end
