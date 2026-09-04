defmodule BlazeXBrowserPhoenix.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :blazex_browser_phoenix

  @session_options [
    store: :cookie,
    key: "_blazex_bh01_phase6",
    signing_salt: "bh01-phase6-signing",
    encryption_salt: "bh01-phase6-encryption",
    same_site: "Strict",
    http_only: true,
    secure: false
  ]

  plug(BlazeXBrowserPhoenix.DeploymentHeaders)
  plug(Plug.Session, @session_options)
  plug(BlazeXBrowserPhoenix.ControlPlug)
  plug(BlazeXBrowserPhoenix.AssetPlug)
  plug(BlazeXBrowserPhoenix.NotFoundPlug)
end
