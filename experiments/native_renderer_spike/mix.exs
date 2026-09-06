defmodule BlazeXNativeRendererSpike.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_native_renderer_spike,
      version: "0.0.0-bh02-phase7",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: [
        {:blazex_core, path: "../../packages/blazex_core"},
        {:blazex_effects, path: "../../packages/blazex_effects"},
        {:blazex_ui_tree, path: "../../packages/blazex_ui_tree"},
        {:blazex_renderer, path: "../../packages/blazex_renderer"}
      ]
    ]
  end

  def application, do: [extra_applications: [:crypto]]
end
