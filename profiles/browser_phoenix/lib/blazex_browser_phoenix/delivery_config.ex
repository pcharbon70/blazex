defmodule BlazeXBrowserPhoenix.DeliveryConfig do
  @moduledoc false

  def root do
    Application.get_env(
      :blazex_browser_phoenix,
      :bh07_static_root,
      Application.app_dir(:blazex_browser_phoenix, "priv/static/bh07")
    )
    |> Path.expand()
  end

  def attestation_path(root \\ root()) do
    Application.get_env(
      :blazex_browser_phoenix,
      :bh07_attestation_path,
      Path.join(root, "entrypoint-attestation.json")
    )
    |> Path.expand()
  end
end
