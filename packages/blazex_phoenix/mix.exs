defmodule BlazeXPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_phoenix,
      version: "0.0.0-bh01",
      elixir: "== 1.17.3",
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:crypto]]

  defp deps, do: []
end
