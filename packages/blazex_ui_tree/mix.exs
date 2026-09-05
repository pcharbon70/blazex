defmodule BlazeXUITree.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_ui_tree,
      version: "0.0.0-bh02",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: [{:blazex_core, path: "../blazex_core"}]
    ]
  end

  def application, do: []
end
