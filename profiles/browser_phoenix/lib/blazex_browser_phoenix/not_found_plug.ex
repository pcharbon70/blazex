defmodule BlazeXBrowserPhoenix.NotFoundPlug do
  @moduledoc false
  import Plug.Conn

  def init(options), do: options

  def call(%Plug.Conn{halted: true} = conn, _options), do: conn
  def call(conn, _options), do: conn |> send_resp(404, "not found") |> halt()
end
