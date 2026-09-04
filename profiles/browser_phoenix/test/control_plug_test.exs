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

  defp request(method, path, headers \\ [], body \\ "") do
    headers
    |> Enum.reduce(conn(method, path, body), fn {name, value}, acc ->
      put_req_header(acc, name, value)
    end)
    |> Map.put(:remote_ip, {127, 0, 0, 1})
    |> @endpoint.call(@endpoint.init([]))
  end
end
