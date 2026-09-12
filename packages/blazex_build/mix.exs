defmodule BlazeXBuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_build,
      version: "0.1.0-dev",
      elixir: ">= 1.17.3 and < 1.19.0",
      deps: []
    ]
  end

  def application, do: []
end
