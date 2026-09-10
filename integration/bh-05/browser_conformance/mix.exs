defmodule BlazeXBH05BrowserConformance.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :blazex_bh05_browser_conformance,
      version: "0.0.0-bh05",
      elixir: "== 1.17.3",
      deps: deps()
    ]

  def application, do: [extra_applications: [:logger]]

  defp deps,
    do: [
      {:blazex_core, path: "../../../packages/blazex_core"},
      {:blazex_ui_tree, path: "../../../packages/blazex_ui_tree"}
    ]
end
