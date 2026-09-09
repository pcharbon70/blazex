defmodule BlazeX.ScheduledEvaluatorTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{RootPort, RootSchedule, SchedulingIntents}
  alias BlazeX.UITree.RootEvaluator

  defmodule Root do
    use BlazeX.Component, role: :root, schema: [props: [], slots: []]
    def mount(_), do: {:state, 0}

    def handle_event(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
      do: {:state, n + d}

    def handle_info(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
      do: {:state, n + d}

    def render(_), do: {:output, {:semantic, 1, %{kind: :group, bindings: [:increment]}}}
    def terminate(_), do: :ok
  end

  defmodule Child do
    use BlazeX.Component, role: :stateful, schema: [props: [], slots: []]
    def init(_), do: {:state, 10}

    def handle_event(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
      do: {:state, n + d}

    def handle_info(%{state: {:present, n}, payload: {:present, %{data: %{"delta" => d}}}}),
      do: {:state, n + d}

    def render(_), do: {:output, {:semantic, 1, %{kind: :group, bindings: [:increment]}}}
    def dispose(_), do: :ok
  end

  defmodule Pure do
    use BlazeX.Component, role: :pure, schema: [props: [], slots: []]
    def render(_), do: {:output, {:semantic, 1, %{kind: :group, bindings: [:increment]}}}
  end

  defp graph do
    entry = %{
      module: Root,
      public_id: "root",
      site: "test",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child", "pure"]
    }

    %{
      reference: "root",
      graph: %{
        "root" => entry,
        "child" => %{entry | module: Child, public_id: "child", key: "child", children: []},
        "pure" => %{entry | module: Pure, public_id: "pure", key: "pure", children: []}
      }
    }
  end

  defp spec do
    {:ok, spec} =
      RootPort.normalize(%{
        root: "r",
        instance: "i",
        owner: "o",
        public_id: "root",
        component: Root,
        props: %{},
        slots: %{},
        capabilities: [],
        fallback: :none,
        timeout_ms: 1000
      })

    spec
  end

  defp policy do
    schema = {:record, [{"delta", {:integer, 1, 9}}]}

    %{
      producers:
        Map.new(["root", "child", "pure"], fn id ->
          {id,
           %{
             component: id,
             classes: [:event, :message],
             routes: [:self, :child, :parent, :root],
             supersedable: []
           }}
        end),
      events: %{increment: schema},
      messages: %{"root" => %{"tick" => schema}, "child" => %{"tick" => schema}},
      components: %{"root" => [:self, :child], "child" => [:self, :parent, :root]}
    }
  end

  defp mounted do
    {:ok, correlation} = RootPort.correlation(spec(), 1, 1, 1, :mount)

    {:ok, candidate} =
      RootEvaluator.prepare(
        graph(),
        %{spec: spec(), operation: :mount, correlation: correlation},
        nil
      )

    candidate
  end

  defp identity(candidate, id),
    do: Enum.find(candidate.state.components, &(&1.public_id == id)).identity

  defp work(candidate, source, target, route, class \\ :message) do
    envelope = %{
      class: class,
      producer: source,
      sequence: 1,
      generation: 1,
      revision: candidate.correlation.revision,
      source: identity(candidate, source),
      target: identity(candidate, target),
      route: route,
      name: if(class == :event, do: :increment, else: "tick"),
      payload: %{"delta" => 2},
      supersedable: false,
      timer: :none
    }

    RootSchedule.normalize(policy(), envelope, candidate, spec())
  end

  defp evaluate(candidate, work) do
    {:ok, correlation} =
      RootPort.correlation(
        spec(),
        1,
        candidate.correlation.revision + 1,
        candidate.correlation.sequence + 1,
        :update
      )

    RootEvaluator.prepare_scheduled(
      graph(),
      %{spec: spec(), operation: :update, correlation: correlation, work: work},
      candidate
    )
  end

  test "typed self child parent and root messages change only the declared target candidate" do
    for {source, target, route} <- [
          {"root", "root", :self},
          {"root", "child", :child},
          {"child", "root", :parent},
          {"child", "root", :root}
        ] do
      old = mounted()
      {:ok, work} = work(old, source, target, route)
      assert :ok = RootEvaluator.admit(graph(), work, old)
      assert {:ok, next, []} = evaluate(old, work)
      before = Enum.find(old.state.components, &(&1.public_id == target)).state

      assert Enum.find(next.state.components, &(&1.public_id == target)).state ==
               {:present, elem(before, 1) + 2}

      assert Enum.find(old.state.components, &(&1.public_id == target)).state == before
    end
  end

  test "events use committed binding and nearest stateful owner, including pure emitters" do
    old = mounted()

    for {source, target, route} <- [
          {"root", "root", :self},
          {"child", "child", :self},
          {"pure", "root", :parent}
        ] do
      {:ok, event} = work(old, source, target, route, :event)
      assert {:ok, _, []} = evaluate(old, event)
      assert {:error, _} = RootEvaluator.admit(graph(), %{event | name: :unbound}, old)
    end

    {:ok, wrong_owner} = work(old, "child", "root", :parent, :event)
    assert {:error, _} = RootEvaluator.admit(graph(), wrong_owner, old)
    assert {:error, :invalid_ingress} = work(old, "pure", "pure", :self, :event)
  end

  test "messages reject missing generations, cross-root targets and undeclared schemas" do
    old = mounted()
    {:ok, message} = work(old, "root", "child", :child)
    assert {:error, _} = RootEvaluator.admit(graph(), %{message | generation: 2}, old)

    assert {:error, _} =
             RootEvaluator.admit(
               graph(),
               %{message | target: %{message.target | root: "foreign"}},
               old
             )

    assert {:error, :invalid_intent} =
             SchedulingIntents.normalize(
               policy(),
               [
                 %{
                   source: identity(old, "child"),
                   actions: [
                     {:message, "parent",
                      %{target: identity(old, "root"), name: "unknown", payload: %{}}}
                   ]
                 }
               ],
               old,
               spec()
             )
  end
end
