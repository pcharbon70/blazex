defmodule BlazeX.ActionEvaluatorTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.RootPort
  alias BlazeX.UITree.RootEvaluator

  defmodule NoCapability do
    use BlazeX.Component, role: :root, schema: [props: [], slots: []]
    def mount(_), do: {:state, 0}
    def effect_result(_), do: :no_change
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule NoResultCallback do
    use BlazeX.Component,
      role: :root,
      capabilities: ["ui.storage"],
      schema: [props: [], slots: []]

    def mount(_), do: {:state, 0}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  test "runtime grants cannot replace the component capability declaration or result callback" do
    for component <- [NoCapability, NoResultCallback] do
      {:ok, spec} =
        RootPort.normalize(%{
          root: "r",
          instance: "i",
          owner: "runtime",
          component: component,
          public_id: "root",
          props: %{},
          slots: %{},
          capabilities: ["ui.storage"],
          fallback: :none,
          timeout_ms: 1000
        })

      config = %{
        reference: "root",
        graph: %{
          "root" => %{
            module: component,
            public_id: "root",
            site: "test",
            key: "root",
            props: %{},
            slots: %{},
            children: []
          }
        }
      }

      {:ok, correlation} = RootPort.correlation(spec, 1, 1, 1, :mount)

      {:ok, candidate} =
        RootEvaluator.prepare(
          config,
          %{spec: spec, operation: :mount, correlation: correlation},
          nil
        )

      action = %{
        kind: :effect_request,
        owner: %{root: "r", path: [], generation: 1},
        request: %{declaration: %{capability: "ui.storage"}}
      }

      assert {:error, _} = RootEvaluator.admit_action(config, action, candidate)
    end
  end
end
