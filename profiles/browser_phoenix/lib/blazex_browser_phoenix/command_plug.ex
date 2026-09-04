defmodule BlazeXBrowserPhoenix.CommandPlug do
  @moduledoc false
  import Plug.Conn

  alias BlazeX.Phoenix.BH01.FixtureAuthority

  @max_body_bytes 2_048
  @route "/bh01/commands/counter-increment"

  def init(options), do: options

  def call(%Plug.Conn{method: "POST", request_path: @route} = conn, _options) do
    conn = fetch_session(conn)

    with :ok <- require_same_origin(conn),
         :ok <- require_json(conn),
         {:ok, body, conn} <- bounded_body(conn),
         {:ok, envelope} <- Jason.decode(body),
         {:ok, result} <-
           FixtureAuthority.execute(
             get_session(conn, :bh01_session_id),
             csrf(conn),
             envelope,
             failure_mode: failure_mode(conn)
           ) do
      respond(conn, 200, result)
    else
      {:error, %{"error" => %{"code" => code}} = result} ->
        respond(conn, status_for(code), result)

      {:error, :cross_origin} ->
        respond(conn, 403, error("origin-invalid"))

      {:error, :content_type} ->
        respond(conn, 415, error("content-type-invalid"))

      {:error, :body_too_large, conn} ->
        respond(conn, 413, error("command-oversized"))

      {:error, :body_invalid, conn} ->
        respond(conn, 400, error("command-body-invalid"))

      {:error, %Jason.DecodeError{}} ->
        respond(conn, 400, error("command-json-invalid"))

      _ ->
        respond(conn, 400, error("command-request-invalid"))
    end
  end

  def call(%Plug.Conn{request_path: "/bh01/commands/" <> _rest} = conn, _options),
    do: respond(conn, 404, error("command-unknown"))

  def call(conn, _options), do: conn

  defp bounded_body(conn) do
    case read_body(conn, length: @max_body_bytes + 1, read_length: @max_body_bytes + 1) do
      {:ok, body, conn} when byte_size(body) <= @max_body_bytes -> {:ok, body, conn}
      {:ok, _body, conn} -> {:error, :body_too_large, conn}
      {:more, _body, conn} -> {:error, :body_too_large, conn}
      _ -> {:error, :body_invalid, conn}
    end
  end

  defp require_same_origin(conn) do
    expected = "#{conn.scheme}://#{conn.host}:#{conn.port}"
    if get_req_header(conn, "origin") == [expected], do: :ok, else: {:error, :cross_origin}
  end

  defp require_json(conn) do
    case get_req_header(conn, "content-type") do
      ["application/json" <> _parameters] -> :ok
      _ -> {:error, :content_type}
    end
  end

  defp csrf(conn), do: get_req_header(conn, "x-bh01-csrf") |> List.first()

  defp failure_mode(conn) do
    if test_control?(conn) do
      case get_req_header(conn, "x-bh01-failure-mode") do
        ["server-error"] -> :server_error
        ["transaction-error"] -> :transaction_error
        _ -> :none
      end
    else
      :none
    end
  end

  defp test_control?(conn) do
    Application.get_env(:blazex_browser_phoenix, :mode) == :test and
      conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] and
      get_req_header(conn, "x-bh01-test-control") == ["enabled"]
  end

  defp status_for(code)
       when code in ["authentication-required", "session-invalid", "session-expired"],
       do: 401

  defp status_for("csrf-invalid"), do: 403
  defp status_for("authorization-denied"), do: 403
  defp status_for("command-unknown"), do: 404
  defp status_for(code) when code in ["state-stale", "idempotency-conflict"], do: 409
  defp status_for("rate-limited"), do: 429
  defp status_for("server-unavailable"), do: 503
  defp status_for("transaction-failed"), do: 500
  defp status_for(_code), do: 422

  defp error(code) do
    %{
      "protocol" => "blazex.bh01.server-result/0.1",
      "status" => "error",
      "correlation_id" => "unavailable",
      "error" => %{"code" => code, "retryable" => code == "server-unavailable"}
    }
  end

  defp respond(conn, status, value) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(status, Jason.encode!(value))
    |> halt()
  end
end
