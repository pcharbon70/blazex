Code.require_file("root-fixtures.exs", __DIR__)

defmodule BlazeX.BH05.SchedulingRoot do
  use BlazeX.Component,
    role: :root,
    schema: [props: [{"count", [type: :integer, default: 0]}], slots: []]

  def mount(%{props: %{"count" => n}}), do: {:state, n}
  def update(%{props: %{"count" => n}}), do: {:state, n}

  def handle_event(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
    do: {:state, n + d}

  def handle_info(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
    do: {:state, n + d}

  def render(%{state: {:present, n}}),
    do:
      {:output,
       {:semantic, 1,
        %{
          kind: :group,
          bindings: [:increment],
          accessibility: %{role: :group, name: Integer.to_string(n)}
        }}}

  def terminate(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.SchedulingChild do
  use BlazeX.Component, role: :stateful, schema: [props: [], slots: []]
  def init(_), do: {:state, 10}

  def handle_event(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
    do: {:state, n + d}

  def handle_info(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
    do: {:state, n + d}

  def render(%{state: {:present, n}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: Integer.to_string(n)}}}

  def dispose(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.SchedulingEvaluatorPort do
  @moduledoc "Test-owned graph snapshots model host removal; no dynamic component registry is introduced."
  alias BlazeX.UITree.RootEvaluator
  def prepare(config, request, prior), do: RootEvaluator.prepare(graph(config), request, prior)

  def prepare_scheduled(config, request, prior),
    do: RootEvaluator.prepare_scheduled(graph(config), request, prior)

  def admit(config, work, prior), do: RootEvaluator.admit(graph(config), work, prior)
  def cleanup(config, prior, reason), do: RootEvaluator.cleanup(graph(config), prior, reason)

  def cleanup_removed(config, prior, next),
    do: RootEvaluator.cleanup_removed(graph(config), prior, next)

  defp graph(config), do: Agent.get(config.graph, & &1)
end

defmodule BlazeX.BH05.SchedulingFixtures do
  alias BlazeX.BH05.{SchedulingRoot, SchedulingChild, SchedulingEvaluatorPort, RootRendererPort}
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Accessibility, Binding, Document, IntentSet, Node}

  def spec(root \\ "schedule"),
    do: %{
      root: root,
      instance: root <> "-instance",
      owner: "runtime",
      component: SchedulingRoot,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 5000
    }

  def graph do
    entry = %{
      module: SchedulingRoot,
      public_id: "root",
      site: "demo",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child"]
    }

    %{
      reference: "root",
      graph: %{
        "root" => entry,
        "child" => %{
          entry
          | module: SchedulingChild,
            public_id: "child",
            key: "child",
            children: []
        }
      }
    }
  end

  def policy do
    schema = {:record, [{"delta", {:integer, 1, 9}}]}

    %{
      producers:
        Map.new(["root", "child"], fn id ->
          {id,
           %{
             component: id,
             classes: [:event, :message, :update, :timer],
             routes: [:self, :child, :parent, :root],
             supersedable: [:event, :update]
           }}
        end),
      events: %{increment: schema},
      messages: %{"root" => %{"tick" => schema}, "child" => %{"tick" => schema}},
      components: %{"root" => [:self, :child], "child" => [:self, :parent, :root]}
    }
  end

  def ports(config),
    do: %{
      evaluator: {SchedulingEvaluatorPort, config},
      renderer: {RootRendererPort, config},
      host: {RootRendererPort, config}
    }

  def identity(root, "root", generation \\ 1), do: %{root: root, path: [], generation: generation}
  def child(root), do: %{root: root, path: [{"child", "demo", :child, "child"}], generation: 1}

  def envelope(root, sequence, changes \\ %{}) do
    Map.merge(
      %{
        class: :event,
        producer: "root",
        sequence: sequence,
        generation: 1,
        revision: 1,
        source: identity(root, "root"),
        target: identity(root, "root"),
        route: :self,
        name: :increment,
        payload: %{"delta" => 1},
        supersedable: false,
        timer: :none
      },
      changes
    )
  end

  def oracle(root, count, child_count \\ 10) do
    {:ok, id} = Identity.new(root, 1)
    {:ok, child_id} = Identity.child(id, {"child", "demo", :child, "child"})
    {:ok, child} = Node.text(child_id, Integer.to_string(child_count))
    {:ok, group} = Node.container(:group, id, [child])
    {:ok, binding} = Binding.new(:increment, id, id)
    {:ok, document} = Document.new(group, [binding])
    {:ok, accessibility} = Accessibility.new(id, :group, name: Integer.to_string(count))
    {:ok, output} = IntentSet.new(document, accessibility: [accessibility])
    output
  end
end
