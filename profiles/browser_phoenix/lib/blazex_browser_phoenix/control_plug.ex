defmodule BlazeXBrowserPhoenix.ControlPlug do
  @moduledoc false
  import Plug.Conn

  alias BlazeX.Phoenix.BH01.FixtureAuthority

  @max_body_bytes 512

  def init(options), do: options

  def call(%Plug.Conn{method: "GET", request_path: "/bh01/health"} = conn, _options) do
    respond(conn, 200, %{
      "protocol" => "blazex.bh01.health/0.1",
      "status" => "ready",
      "profile" => "browser-phoenix",
      "phase" => 6
    })
  end

  def call(%Plug.Conn{method: "POST", request_path: "/bh01/test/session"} = conn, _options) do
    with true <- test_control?(conn),
         true <- same_origin?(conn),
         {:ok, body, conn} <- bounded_body(conn),
         {:ok, %{"identity_id" => identity_id}} <- Jason.decode(body),
         true <- identity_id in ["operator", "viewer", "disabled"],
         {:ok, session} <- FixtureAuthority.issue_session(identity_id) do
      conn
      |> fetch_session()
      |> put_session(:bh01_session_id, session["session_id"])
      |> respond(201, Map.drop(session, ["session_id"]))
    else
      {:error, "identity-disabled"} -> respond(conn, 403, error("identity-disabled"))
      _ -> respond(conn, 400, error("test-session-invalid"))
    end
  end

  def call(%Plug.Conn{method: "DELETE", request_path: "/bh01/test/session"} = conn, _options) do
    if test_control?(conn) and same_origin?(conn) do
      conn
      |> fetch_session()
      |> clear_session()
      |> respond(200, %{"status" => "cleared"})
    else
      respond(conn, 404, error("not-found"))
    end
  end

  def call(%Plug.Conn{method: "POST", request_path: "/bh01/test/reset"} = conn, _options) do
    if test_control?(conn) do
      respond(conn, 200, FixtureAuthority.reset())
    else
      respond(conn, 404, error("not-found"))
    end
  end

  def call(%Plug.Conn{method: "GET", request_path: "/bh01/test/state"} = conn, _options) do
    if test_control?(conn) do
      respond(conn, 200, FixtureAuthority.snapshot())
    else
      respond(conn, 404, error("not-found"))
    end
  end

  def call(conn, _options), do: conn

  defp bounded_body(conn) do
    case read_body(conn, length: @max_body_bytes, read_length: @max_body_bytes) do
      {:ok, body, conn} when byte_size(body) <= @max_body_bytes -> {:ok, body, conn}
      _ -> {:error, :body_invalid}
    end
  end

  defp same_origin?(conn) do
    expected = "#{conn.scheme}://#{conn.host}:#{conn.port}"
    get_req_header(conn, "origin") == [expected]
  end

  defp test_control?(conn) do
    Application.get_env(:blazex_browser_phoenix, :mode) == :test and
      conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] and
      get_req_header(conn, "x-bh01-test-control") == ["enabled"]
  end

  defp error(code), do: %{"protocol" => "blazex.bh01.error/0.1", "error" => %{"code" => code}}

  defp respond(conn, status, value) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(status, Jason.encode!(value))
    |> halt()
  end
end
