defmodule BlazeXBrowserPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_browser_phoenix,
      version: "0.0.0-bh01",
      elixir: ">= 1.18.0",
      elixirc_paths: ["lib"],
      deps: deps()
    ]
  end

  def application, do: []

  defp deps, do: []
end
