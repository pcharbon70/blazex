defmodule BlazeXBrowserPhoenix.ExecutionPlug do
  @moduledoc false
  import Plug.Conn

  alias BlazeX.Phoenix.{CommandExecution, OriginPolicy}

  @path "/bh07/commands/execute"
  @csrf_header "x-blazex-csrf"
  @max_body_bytes 2_048

  def init(options), do: options

  def call(%Plug.Conn{method: "POST", request_path: @path} = conn, _options) do
    conn = fetch_session(conn)

    with :ok <- same_origin(conn),
         :ok <- require_json(conn),
         {:ok, body, conn} <- bounded_body(conn),
         {:ok, envelope} <- Jason.decode(body),
         {:ok, session_id, cookie_csrf} <- session_values(conn),
         [supplied_csrf] <- get_req_header(conn, @csrf_header),
         true <- secure_equal?(cookie_csrf, supplied_csrf),
         {:ok, result} <- CommandExecution.execute(session_id, supplied_csrf, envelope) do
      respond(conn, 200, result)
    else
      {:error, :body_too_large, conn} -> respond(conn, 413, error("command-oversized"))
      {:error, :body_invalid, conn} -> respond(conn, 400, error("command-body-invalid"))
      {:error, %Jason.DecodeError{}} -> respond(conn, 400, error("command-json-invalid"))
      {:error, "origin-invalid"} -> respond(conn, 403, error("origin-invalid"))
      {:error, "authentication-required"} -> respond(conn, 401, error("authentication-required"))
      {:error, code} when is_binary(code) -> respond(conn, status_for_code(code), error(code))
      {:error, result} when is_map(result) -> respond(conn, status_for(result), result)
      _ -> respond(conn, 403, error("csrf-invalid"))
    end
  end

  def call(%Plug.Conn{request_path: @path} = conn, _options) do
    conn |> put_resp_header("allow", "POST") |> respond(405, error("method-not-allowed"))
  end

  def call(conn, _options), do: conn

  defp bounded_body(conn) do
    case read_body(conn, length: @max_body_bytes + 1, read_length: @max_body_bytes + 1) do
      {:ok, body, conn} when byte_size(body) <= @max_body_bytes -> {:ok, body, conn}
      {:ok, _body, conn} -> {:error, :body_too_large, conn}
      {:more, _body, conn} -> {:error, :body_too_large, conn}
      _ -> {:error, :body_invalid, conn}
    end
  end

  defp require_json(conn) do
    case get_req_header(conn, "content-type") do
      ["application/json"] -> :ok
      _ -> {:error, "content-type-invalid"}
    end
  end

  defp same_origin(conn),
    do: OriginPolicy.authorize(get_req_header(conn, "origin"), conn.scheme, conn.host, conn.port)

  defp session_values(conn) do
    case {get_session(conn, :bh07_session_id), get_session(conn, :bh07_csrf_token)} do
      {session_id, csrf_token} when is_binary(session_id) and is_binary(csrf_token) ->
        {:ok, session_id, csrf_token}

      _ ->
        {:error, "authentication-required"}
    end
  end

  defp secure_equal?(left, right) when is_binary(left) and is_binary(right),
    do: byte_size(left) == byte_size(right) and :crypto.hash_equals(left, right)

  defp secure_equal?(_left, _right), do: false

  defp status_for(%{"error" => %{"code" => code}}), do: status_for_code(code)

  defp status_for_code(code) do
    case code do
      "content-type-invalid" -> 415
      code when code in ["session-invalid", "authentication-required"] -> 401
      code when code in ["csrf-invalid", "authorization-denied"] -> 403
      "command-unknown" -> 404
      code when code in ["idempotency-conflict", "state-stale"] -> 409
      code when code in ["admission-rate-limited", "execution-rate-limited"] -> 429
      code when code in ["admission-capacity", "execution-capacity"] -> 503
      _ -> 422
    end
  end

  defp error(code) do
    %{
      "protocol" => "blazex.bh07.command-result/1",
      "status" => "error",
      "correlation_id" => "unavailable",
      "error" => %{
        "code" => code,
        "retryable" => false,
        "replayed" => false,
        "executed" => false
      }
    }
  end

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
