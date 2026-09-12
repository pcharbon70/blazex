defmodule BlazeXBH06VerticalSlice.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_bh06_vertical_slice,
      version: "0.0.0-bh06-phase1",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: deps()
    ]
  end

  def application, do: [extra_applications: []]

  defp deps do
    [
      {:blazex_build, path: "../../../packages/blazex_build", runtime: false},
      {:blazex_core, path: "../../../packages/blazex_core"},
      {:blazex_ui_tree, path: "../../../packages/blazex_ui_tree"}
    ]
  end
end
