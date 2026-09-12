defmodule BlazeXBrowserPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_browser_phoenix,
      version: "0.0.0-bh01",
      elixir: ">= 1.17.3 and < 1.19.0",
      elixirc_paths: ["lib"],
      deps: deps()
    ]
  end

  def application do
    [
      mod: {BlazeXBrowserPhoenix.Application, []},
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:blazex_phoenix, path: "../../packages/blazex_phoenix"},
      {:phoenix, "== 1.8.13"},
      {:bandit, "== 1.12.5"},
      {:jason, "== 1.4.5"}
    ]
  end
end
