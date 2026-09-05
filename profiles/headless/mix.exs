defmodule BlazeXHeadlessProfile.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_headless_profile,
      version: "0.0.0-bh02",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: [
        {:blazex_core, path: "../../packages/blazex_core"},
        {:blazex_effects, path: "../../packages/blazex_effects"},
        {:blazex_ui_tree, path: "../../packages/blazex_ui_tree"},
        {:blazex_renderer, path: "../../packages/blazex_renderer"},
        {:blazex_renderer_headless, path: "../../packages/blazex_renderer_headless"},
        {:blazex_test, path: "../../packages/blazex_test"}
      ]
    ]
  end

  def application, do: []
end
