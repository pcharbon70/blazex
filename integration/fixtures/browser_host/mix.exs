defmodule BlazeX.BH01.BrowserHost.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_bh01_browser_host,
      version: "0.0.0-bh01",
      elixir: "== 1.17.3",
      start_permanent: false,
      deps: [{:popcorn, "== 0.3.3", runtime: false}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
