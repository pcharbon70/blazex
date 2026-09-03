defmodule BlazeXPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_phoenix,
      version: "0.0.0-bh01",
      elixir: ">= 1.18.0",
      deps: deps()
    ]
  end

  def application, do: []

  defp deps, do: []
end
