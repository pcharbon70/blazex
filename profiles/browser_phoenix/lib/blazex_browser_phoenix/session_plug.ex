defmodule BlazeXBrowserPhoenix.SessionPlug do
  @moduledoc false
  import Plug.Conn

  alias BlazeX.Phoenix.{OriginPolicy, SessionRegistry}

  @session_path "/bh07/session"
  @csrf_path "/bh07/csrf/rotate"
  @issue_path "/bh07/test/session"
  @reset_path "/bh07/test/reset"
  @control_header "x-bh07-test-control"
  @csrf_header "x-blazex-csrf"
  @max_body_bytes 128
  @test_identities %{"operator" => "Operator", "viewer" => "Viewer"}

  def init(options), do: options

  def call(%Plug.Conn{method: "GET", request_path: @session_path} = conn, _options) do
    conn = fetch_session(conn)

    case session_values(conn) do
      {session_id, csrf_token} when is_binary(session_id) and is_binary(csrf_token) ->
        case SessionRegistry.authenticate(session_id, csrf_token) do
          {:ok, projection} -> respond(conn, 200, authenticated(projection, csrf_token))
          {:error, _code} -> conn |> invalidate(session_id) |> respond(200, anonymous())
        end

      {session_id, _csrf_token} when is_binary(session_id) ->
        conn |> invalidate(session_id) |> respond(200, anonymous())

      _ ->
        conn |> clear_bh07_session() |> respond(200, anonymous())
    end
  end

  def call(%Plug.Conn{method: "DELETE", request_path: @session_path} = conn, _options) do
    conn = fetch_session(conn)

    with :ok <- same_origin(conn) do
      case session_values(conn) do
        {session_id, csrf_token} when is_binary(session_id) and is_binary(csrf_token) ->
          with [supplied] <- get_req_header(conn, @csrf_header),
               true <- secure_equal?(csrf_token, supplied),
               {:ok, _projection} <- SessionRegistry.authenticate(session_id, supplied) do
            conn |> invalidate(session_id) |> respond(200, anonymous())
          else
            _ -> respond(conn, 403, error("csrf-invalid"))
          end

        _ ->
          conn |> clear_bh07_session() |> respond(200, anonymous())
      end
    else
      _ -> respond(conn, 403, error("origin-invalid"))
    end
  end

  def call(%Plug.Conn{request_path: @session_path} = conn, _options) do
    conn
    |> put_resp_header("allow", "GET, DELETE")
    |> respond(405, error("method-not-allowed"))
  end

  def call(%Plug.Conn{method: "POST", request_path: @csrf_path} = conn, _options) do
    conn = fetch_session(conn)

    with :ok <- same_origin(conn),
         {session_id, csrf_token} when is_binary(session_id) and is_binary(csrf_token) <-
           session_values(conn),
         [supplied] <- get_req_header(conn, @csrf_header),
         true <- secure_equal?(csrf_token, supplied),
         {:ok, rotated} <- SessionRegistry.rotate_csrf(session_id, supplied) do
      conn
      |> configure_session(renew: true)
      |> put_session(:bh07_csrf_token, rotated["csrf_token"])
      |> respond(200, authenticated(rotated["projection"], rotated["csrf_token"]))
    else
      {:error, "origin-invalid"} ->
        respond(conn, 403, error("origin-invalid"))

      {:error, "session-invalid"} ->
        conn |> clear_bh07_session() |> respond(401, error("session-invalid"))

      _ ->
        respond(conn, 403, error("csrf-invalid"))
    end
  end

  def call(%Plug.Conn{request_path: @csrf_path} = conn, _options) do
    conn
    |> put_resp_header("allow", "POST")
    |> respond(405, error("method-not-allowed"))
  end

  def call(%Plug.Conn{method: "POST", request_path: @issue_path} = conn, _options) do
    with true <- test_control?(conn),
         :ok <- same_origin(conn),
         {:ok, body, conn} <- bounded_body(conn),
         ["application/json"] <- get_req_header(conn, "content-type"),
         {:ok, %{"identity_id" => identity_id} = payload} <- Jason.decode(body),
         true <- map_size(payload) == 1,
         {:ok, display_label} <- Map.fetch(@test_identities, identity_id) do
      conn = conn |> fetch_session() |> revoke_current()

      with {:ok, issued} <- SessionRegistry.issue(identity_id, display_label) do
        conn
        |> configure_session(renew: true)
        |> put_session(:bh07_session_id, issued["session_id"])
        |> put_session(:bh07_csrf_token, issued["csrf_token"])
        |> respond(201, authenticated(issued["projection"], issued["csrf_token"]))
      end
    else
      _ -> respond(conn, 404, error("not-found"))
    end
  end

  def call(%Plug.Conn{method: "POST", request_path: @reset_path} = conn, _options) do
    if test_control?(conn) and same_origin(conn) == :ok do
      SessionRegistry.reset()

      conn
      |> fetch_session()
      |> clear_bh07_session()
      |> respond(200, anonymous())
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

  defp test_control?(conn) do
    Application.get_env(:blazex_browser_phoenix, :mode) == :test and
      conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] and
      get_req_header(conn, @control_header) == ["enabled"]
  end

  defp same_origin(conn),
    do: OriginPolicy.authorize(get_req_header(conn, "origin"), conn.scheme, conn.host, conn.port)

  defp session_values(conn),
    do: {get_session(conn, :bh07_session_id), get_session(conn, :bh07_csrf_token)}

  defp revoke_current(conn) do
    case get_session(conn, :bh07_session_id) do
      session_id when is_binary(session_id) -> SessionRegistry.revoke(session_id)
      _ -> :ok
    end

    clear_bh07_session(conn)
  end

  defp invalidate(conn, session_id) do
    SessionRegistry.revoke(session_id)
    clear_bh07_session(conn)
  end

  defp clear_bh07_session(conn) do
    conn |> delete_session(:bh07_session_id) |> delete_session(:bh07_csrf_token)
  end

  defp secure_equal?(left, right) when is_binary(left) and is_binary(right),
    do: byte_size(left) == byte_size(right) and :crypto.hash_equals(left, right)

  defp secure_equal?(_left, _right), do: false

  defp anonymous do
    %{"protocol" => "blazex.bh07.session/1", "state" => "anonymous"}
  end

  defp authenticated(projection, csrf_token), do: Map.put(projection, "csrf_token", csrf_token)

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
