defmodule BlazeX.RootEvaluatorTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.RootPort
  alias BlazeX.UITree.RootEvaluator

  defmodule Root do
    use BlazeX.Component,
      role: :root,
      schema: [
        props: [
          {"count", [type: :integer, default: 0]},
          {"fault", [type: :string, default: "none"]}
        ],
        slots: []
      ]

    def mount(%{props: %{"fault" => "mount"}}), do: :erlang.error(:private_mount)
    def mount(%{props: %{"count" => count}}), do: {:state, count}
    def update(%{props: %{"fault" => "update"}}), do: :erlang.raise(:exit, :private_update, [])

    def update(%{props: %{"fault" => "action"}, state: {:present, value}}),
      do: {:actions, value, [{:message, "parent", %{name: :change, payload: %{}}}]}

    def update(%{props: %{"count" => count}, state: {:present, count}}), do: :no_change
    def update(%{props: %{"count" => count}}), do: {:state, count}
    def render(%{props: %{"fault" => "render"}}), do: :erlang.raise(:throw, :private_render, [])

    def render(%{props: %{"fault" => "semantic"}}),
      do: {:output, {:semantic, 1, %{kind: :unknown}}}

    def render(input) do
      :ok = BlazeX.Component.Input.validate(input)
      {:output, {:semantic, 1, %{kind: :group}}}
    end

    def terminate(%{props: %{"fault" => "cleanup"}}), do: {:rejected, :failed}
    def terminate(input), do: BlazeX.Component.Input.validate(input)
  end

  defmodule Child do
    use BlazeX.Component, role: :stateful, schema: [props: [], slots: []]

    def init(input) do
      :ok = BlazeX.Component.Input.validate(input)
      {:state, 7}
    end

    def render(%{state: {:present, value}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: Integer.to_string(value)}}}

    def dispose(input), do: BlazeX.Component.Input.validate(input)
  end

  defp spec(props) do
    {:ok, value} =
      RootPort.normalize(%{
        root: "r",
        instance: "i",
        owner: "o",
        public_id: "root",
        component: Root,
        props: props,
        slots: %{},
        capabilities: [],
        fallback: :none,
        timeout_ms: 1000
      })

    value
  end

  defp config do
    root = %{
      module: Root,
      public_id: "root",
      site: "test",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child"]
    }

    %{
      reference: "root",
      graph: %{
        "root" => root,
        "child" => %{root | module: Child, public_id: "child", key: "child", children: []}
      }
    }
  end

  defp prepare(props \\ %{}, prior \\ nil, operation \\ :mount, config \\ config()) do
    old = if prior, do: prior.correlation, else: %{generation: 1, revision: 0, sequence: 0}
    generation = old.generation + if(operation == :replace, do: 1, else: 0)

    {:ok, correlation} =
      RootPort.correlation(
        spec(props),
        generation,
        if(operation == :replace, do: 1, else: old.revision + 1),
        old.sequence + 1,
        operation
      )

    RootEvaluator.prepare(
      config,
      %{spec: spec(props), operation: operation, correlation: correlation},
      prior
    )
  end

  test "root mount, nested init, retained update and no-op are immutable candidates" do
    assert {:ok, first} = prepare()

    assert Enum.map(first.state.components, &{&1.role, &1.state}) == [
             root: {:present, 0},
             stateful: {:present, 7}
           ]

    assert {:ok, second} = prepare(%{"count" => 2}, first, :update)
    assert Enum.map(second.state.components, & &1.state) == [{:present, 2}, {:present, 7}]
    assert hd(first.state.components).state == {:present, 0}
    assert {:ok, noop} = prepare(%{"count" => 2}, second, :update)
    assert noop.state_digest == second.state_digest
    assert noop.final_digest != second.final_digest
    assert :ok = RootEvaluator.cleanup(config(), noop, :shutdown)
  end

  test "mount update render semantic and action failures are redacted" do
    assert {:error, :semantic_rejected} = prepare(%{"fault" => "mount"})
    {:ok, first} = prepare()

    for fault <- ["update", "render", "semantic", "action"] do
      assert {:error, :semantic_rejected} = prepare(%{"fault" => fault}, first, :update)
    end

    assert hd(first.state.components).state == {:present, 0}
  end

  test "replacement resets generation and plans deepest-first cleanup without invoking it" do
    {:ok, old} = prepare(%{"fault" => "cleanup"})
    assert {:ok, fresh} = prepare(%{"count" => 10}, old, :replace)
    assert fresh.correlation.generation == 2
    assert Enum.map(fresh.token.disposals, & &1.callback) == [:dispose, :terminate]
    assert {:error, :semantic_rejected} = RootEvaluator.cleanup(config(), old, :replace)
    assert :ok = RootEvaluator.cleanup(config(), fresh, :removal)
  end

  test "invalid graphs and root/nested role inversion fail before publication" do
    for bad <- [
          put_in(config(), [:graph, "child", :module], Root),
          put_in(config(), [:graph, "child", :children], ["root"]),
          put_in(config(), [:graph, "child", :props], %{bad: self()})
        ] do
      assert {:error, :semantic_rejected} = prepare(%{}, nil, :mount, bad)
    end
  end

  test "tampered accepted candidate and different component fingerprint reject" do
    {:ok, first} = prepare()

    assert {:error, :semantic_rejected} =
             prepare(%{}, %{first | state_digest: String.duplicate("0", 64)}, :update)

    changed = put_in(config(), [:graph, "child", :public_id], "changed")
    assert {:ok, _} = prepare(%{}, first, :replace, changed)
    forged = put_in(first, [:token, :output_digest], "fake")
    # Extra opaque adapter keys are not public authority; public summary remains bound.
    assert RootPort.summary(forged) == RootPort.summary(first)
  end
end
