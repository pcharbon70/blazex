defmodule BlazeXBrowserPhoenix.BootstrapPlug do
  @moduledoc false
  import Plug.Conn

  alias BlazeX.Phoenix.PublicBootstrap
  alias BlazeXBrowserPhoenix.DeliveryConfig
  alias BlazeXBrowserPhoenix.StaticDeliveryCache

  @path "/bh07/bootstrap.json"

  def init(options), do: options

  def call(%Plug.Conn{request_path: @path, method: method} = conn, _options)
      when method in ["GET", "HEAD"] do
    root = DeliveryConfig.root()

    with {:ok, delivery} <-
           StaticDeliveryCache.fetch(root, DeliveryConfig.attestation_path(root)),
         {:ok, bootstrap} <- build(delivery) do
      serve(conn, bootstrap)
    else
      _ -> conn
    end
  end

  def call(%Plug.Conn{request_path: @path} = conn, _options) do
    conn
    |> put_resp_header("allow", "GET, HEAD")
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(405, "")
    |> halt()
  end

  def call(conn, _options), do: conn

  defp build(delivery) do
    public_state = Application.get_env(:blazex_browser_phoenix, :bh07_public_bootstrap, %{})
    {:ok, PublicBootstrap.build!(delivery, public_state)}
  rescue
    ArgumentError -> {:error, :bootstrap_invalid}
  end

  defp serve(conn, bootstrap) do
    conn =
      conn
      |> put_resp_header("content-type", "application/json")
      |> put_resp_header("content-length", Integer.to_string(bootstrap.bytes))
      |> put_resp_header("cache-control", "no-store")
      |> put_resp_header("etag", bootstrap.etag)
      |> put_resp_header("x-content-type-options", "nosniff")

    cond do
      bootstrap.etag in get_req_header(conn, "if-none-match") ->
        conn |> delete_resp_header("content-length") |> send_resp(304, "") |> halt()

      conn.method == "HEAD" ->
        conn |> send_resp(200, "") |> halt()

      true ->
        conn |> send_resp(200, bootstrap.body) |> halt()
    end
  end
end
