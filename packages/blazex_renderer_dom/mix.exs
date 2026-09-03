defmodule BlazeXRendererDOM.MixProject do
  use Mix.Project

  def project do
    [
      app: :blazex_renderer_dom,
      version: "0.0.0-bh01",
      elixir: "== 1.17.3",
      deps: deps()
    ]
  end

  def application, do: []

  defp deps, do: []
end
