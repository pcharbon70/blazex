defmodule BlazeX.BH05.RootCounter do
  use BlazeX.Component,
    role: :root,
    schema: [
      props: [
        {"count", [type: :integer, default: 1]},
        {"fault", [type: :string, default: "none"]}
      ],
      slots: []
    ]

  def mount(%{props: %{"fault" => "mount"}}), do: :erlang.error(:private_mount_detail)
  def mount(%{props: %{"count" => value}}), do: {:state, value}

  def update(%{props: %{"fault" => "update"}}),
    do: :erlang.raise(:exit, :private_update_detail, [])

  def update(%{props: %{"fault" => "effect"}, state: {:present, value}}),
    do: {:actions, value, [{:effect, "request", %{}}]}

  def update(%{props: %{"count" => value}, state: {:present, value}}), do: :no_change
  def update(%{props: %{"count" => value}}), do: {:state, value}

  def render(%{props: %{"fault" => "render"}}),
    do: :erlang.raise(:throw, :private_render_detail, [])

  def render(%{props: %{"fault" => "semantic"}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: "invalid parent"}}}

  def render(%{state: {:present, value}} = input) do
    :ok = BlazeX.Component.Input.validate(input)

    {:output,
     {:semantic, 1,
      %{kind: :group, accessibility: %{role: :group, name: Integer.to_string(value)}}}}
  end

  def terminate(%{props: %{"fault" => "cleanup"}}), do: {:rejected, :failed}
  def terminate(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.RootChild do
  use BlazeX.Component, role: :stateful, schema: [props: [], slots: []]

  def init(input) do
    :ok = BlazeX.Component.Input.validate(input)
    {:state, 7}
  end

  def render(%{state: {:present, value}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: Integer.to_string(value)}}}

  def dispose(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.RootRendererPort do
  @moduledoc "Deterministic integration double around the public headless renderer session. Private Agent state belongs to the test adapter, never the component."
  @behaviour BlazeX.Component.RootPort.Renderer
  @behaviour BlazeX.Component.RootPort.Host
  alias BlazeX.Renderer.{Headless, Session}

  def submit(config, correlation, candidate) do
    result =
      Agent.get_and_update(config.state, fn state ->
        result =
          case correlation.operation do
            :mount -> Session.mount(Headless, candidate.token.output)
            :update -> Session.update(state.accepted, candidate.token.output)
            :replace -> Session.replace(state.accepted, candidate.token.output)
            :dispose -> if(state.accepted, do: Session.dispose(state.accepted), else: {:ok, nil})
          end

        case result do
          {:ok, renderer} ->
            {:ok,
             %{
               state
               | pending: %{correlation: correlation, before: state.accepted, after: renderer}
             }}

          _ ->
            {{:error, :renderer_rejected}, state}
        end
      end)

    send(config.observer, {:root_submission, correlation, candidate})
    result
  end

  def cancel(config, correlation) do
    Agent.get_and_update(config.state, fn state ->
      if state.pending && state.pending.correlation == correlation,
        do: {:ok, %{state | accepted: state.pending.before, pending: nil}},
        else: {:ok, state}
    end)
  end

  def commit(config, correlation) do
    Agent.get_and_update(config.state, fn state ->
      if state.pending && state.pending.correlation == correlation,
        do: {:ok, %{state | accepted: state.pending.after}},
        else: {{:error, :stale}, state}
    end)
  end

  def snapshot(config), do: Agent.get(config.state, & &1.accepted)

  def notify(config, record) do
    send(config.observer, {:root_observation, record})
    :ok
  end
end

defmodule BlazeX.BH05.RootFixtures do
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Accessibility, Document, IntentSet, Node, RootEvaluator}
  alias BlazeX.BH05.{RootChild, RootCounter, RootRendererPort}

  def spec(props \\ %{}),
    do: %{
      root: "demo",
      instance: "demo-instance",
      owner: "runtime",
      component: RootCounter,
      public_id: "root",
      props: props,
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 5000
    }

  def ports(config) do
    root = %{
      module: RootCounter,
      public_id: "root",
      site: "demo",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child"]
    }

    graph = %{
      "root" => root,
      "child" => %{root | module: RootChild, public_id: "child", key: "child", children: []}
    }

    %{
      evaluator: {RootEvaluator, %{reference: "root", graph: graph}},
      renderer: {RootRendererPort, config},
      host: {RootRendererPort, config}
    }
  end

  # Independent semantic oracle, built without callback evaluation/planner internals.
  def oracle(count, generation \\ 1) do
    {:ok, root} = Identity.new("demo", generation)
    {:ok, child_id} = Identity.child(root, {"child", "demo", :child, "child"})
    {:ok, child} = Node.text(child_id, "7")
    {:ok, group} = Node.container(:group, root, [child])
    {:ok, document} = Document.new(group)
    {:ok, accessibility} = Accessibility.new(root, :group, name: Integer.to_string(count))
    {:ok, output} = IntentSet.new(document, accessibility: [accessibility])
    output
  end
end
