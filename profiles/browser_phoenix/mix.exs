defmodule BlazeXBrowserPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_browser_phoenix,
      version: "0.0.0-bh01",
      elixir: "== 1.17.3",
      elixirc_paths: ["lib"],
      deps: deps()
    ]
  end

  def application, do: []

  defp deps do
    [
      {:phoenix, "== 1.8.13"},
      {:phoenix_live_view, "== 1.2.11"},
      {:local_live_view, "== 0.1.0"},
      {:bandit, "== 1.12.5"},
      {:igniter, "== 0.7.9", runtime: false, override: true}
    ]
  end
end
