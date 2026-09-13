defmodule BlazeXBrowserPhoenix.SessionPlug do
  @moduledoc false
  import Plug.Conn

  alias BlazeX.Phoenix.SessionRegistry

  @session_path "/bh07/session"
  @issue_path "/bh07/test/session"
  @reset_path "/bh07/test/reset"
  @control_header "x-bh07-test-control"
  @max_body_bytes 128
  @test_identities %{"operator" => "Operator", "viewer" => "Viewer"}

  def init(options), do: options

  def call(%Plug.Conn{method: "GET", request_path: @session_path} = conn, _options) do
    conn = fetch_session(conn)

    case get_session(conn, :bh07_session_id) do
      session_id when is_binary(session_id) ->
        case SessionRegistry.lookup(session_id) do
          {:ok, projection} -> respond(conn, 200, projection)
          {:error, _code} -> conn |> delete_session(:bh07_session_id) |> respond(200, anonymous())
        end

      _ ->
        respond(conn, 200, anonymous())
    end
  end

  def call(%Plug.Conn{method: "DELETE", request_path: @session_path} = conn, _options) do
    conn = fetch_session(conn)

    if same_origin?(conn) do
      case get_session(conn, :bh07_session_id) do
        session_id when is_binary(session_id) -> SessionRegistry.revoke(session_id)
        _ -> :ok
      end

      conn |> delete_session(:bh07_session_id) |> respond(200, anonymous())
    else
      respond(conn, 403, error("origin-invalid"))
    end
  end

  def call(%Plug.Conn{request_path: @session_path} = conn, _options) do
    conn
    |> put_resp_header("allow", "GET, DELETE")
    |> respond(405, error("method-not-allowed"))
  end

  def call(%Plug.Conn{method: "POST", request_path: @issue_path} = conn, _options) do
    with true <- test_control?(conn),
         true <- same_origin?(conn),
         {:ok, body, conn} <- bounded_body(conn),
         ["application/json"] <- get_req_header(conn, "content-type"),
         {:ok, %{"identity_id" => identity_id} = payload} <- Jason.decode(body),
         true <- map_size(payload) == 1,
         {:ok, display_label} <- Map.fetch(@test_identities, identity_id),
         {:ok, issued} <- SessionRegistry.issue(identity_id, display_label) do
      conn = fetch_session(conn)

      case get_session(conn, :bh07_session_id) do
        prior when is_binary(prior) -> SessionRegistry.revoke(prior)
        _ -> :ok
      end

      conn
      |> configure_session(renew: true)
      |> put_session(:bh07_session_id, issued["session_id"])
      |> respond(201, issued["projection"])
    else
      _ -> respond(conn, 404, error("not-found"))
    end
  end

  def call(%Plug.Conn{method: "POST", request_path: @reset_path} = conn, _options) do
    if test_control?(conn) and same_origin?(conn) do
      SessionRegistry.reset()

      conn
      |> fetch_session()
      |> delete_session(:bh07_session_id)
      |> respond(200, anonymous())
    else
      conn
    end
  end

  def call(conn, _options), do: conn

  defp bounded_body(conn) do
    case read_body(conn, length: @max_body_bytes, read_length: @max_body_bytes) do
      {:ok, body, conn} when byte_size(body) <= @max_body_bytes -> {:ok, body, conn}
      _ -> {:error, :body_invalid}
    end
  end

  defp test_control?(conn) do
    Application.get_env(:blazex_browser_phoenix, :mode) == :test and
      conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] and
      get_req_header(conn, @control_header) == ["enabled"]
  end

  defp same_origin?(conn) do
    expected = "#{conn.scheme}://#{conn.host}:#{conn.port}"
    get_req_header(conn, "origin") == [expected]
  end

  defp anonymous do
    %{"protocol" => "blazex.bh07.session/1", "state" => "anonymous"}
  end

  defp error(code),
    do: %{"protocol" => "blazex.bh07.session-error/1", "error" => %{"code" => code}}

  defp respond(conn, status, value) do
    body = Jason.encode!(value)

    conn
    |> put_resp_header("content-type", "application/json")
    |> put_resp_header("content-length", Integer.to_string(byte_size(body)))
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> send_resp(status, body)
    |> halt()
  end
end
