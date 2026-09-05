defmodule BlazeXRendererDOM.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_renderer_dom,
      version: "0.0.0-bh02",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: [
        {:blazex_core, path: "../blazex_core"},
        {:blazex_effects, path: "../blazex_effects"},
        {:blazex_ui_tree, path: "../blazex_ui_tree"},
        {:blazex_renderer, path: "../blazex_renderer"}
      ]
    ]
  end

  def application, do: [extra_applications: [:crypto]]
end
