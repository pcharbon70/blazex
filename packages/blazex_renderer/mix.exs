defmodule BlazeXRenderer.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_renderer,
      version: "0.0.0-bh02",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: [
        {:blazex_core, path: "../blazex_core"},
        {:blazex_effects, path: "../blazex_effects"},
        {:blazex_ui_tree, path: "../blazex_ui_tree"}
      ]
    ]
  end

  def application, do: []
end
