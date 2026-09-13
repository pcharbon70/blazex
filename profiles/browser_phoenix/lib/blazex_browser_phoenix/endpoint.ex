defmodule BlazeXBrowserPhoenix.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :blazex_browser_phoenix

  @session_options [
    store: :cookie,
    key: "_blazex_browser_phoenix",
    signing_salt: "browser-phoenix-signing",
    encryption_salt: "browser-phoenix-encryption",
    same_site: "Strict",
    http_only: true,
    secure: false
  ]

  socket("/bh07/socket", BlazeXBrowserPhoenix.Socket,
    websocket: [
      connect_info: [session: @session_options],
      check_csrf: false,
      max_frame_size: 2_048
    ],
    longpoll: false
  )

  plug(BlazeXBrowserPhoenix.DeploymentHeaders)
  plug(Plug.Session, @session_options)
  plug(BlazeXBrowserPhoenix.SessionPlug)
  plug(BlazeXBrowserPhoenix.ExecutionPlug)
  plug(BlazeXBrowserPhoenix.AdmissionPlug)
  plug(BlazeXBrowserPhoenix.ControlPlug)
  plug(BlazeXBrowserPhoenix.CommandPlug)
  plug(BlazeXBrowserPhoenix.BootstrapPlug)
  plug(BlazeXBrowserPhoenix.AssetPlug)
  plug(BlazeXBrowserPhoenix.NotFoundPlug)
end
