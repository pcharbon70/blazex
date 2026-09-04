defmodule BlazeXBrowserPhoenix.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :blazex_browser_phoenix

  plug(BlazeXBrowserPhoenix.DeploymentHeaders)
  plug(BlazeXBrowserPhoenix.AssetPlug)
  plug(BlazeXBrowserPhoenix.NotFoundPlug)
end
