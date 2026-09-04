defmodule BlazeXBrowserPhoenix.DeploymentHeaders do
  @moduledoc false
  import Plug.Conn

  @csp "default-src 'none'; script-src 'self' blob: 'unsafe-eval'; worker-src 'self' blob:; connect-src 'self'; frame-src 'self'; style-src 'self'; img-src 'self'; base-uri 'self'; form-action 'none'"

  def init(options), do: options

  def call(conn, _options) do
    conn
    |> put_resp_header("cross-origin-opener-policy", "same-origin")
    |> put_resp_header("cross-origin-embedder-policy", "require-corp")
    |> put_resp_header("cross-origin-resource-policy", "same-origin")
    |> put_resp_header("content-security-policy", @csp)
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("referrer-policy", "no-referrer")
  end
end
