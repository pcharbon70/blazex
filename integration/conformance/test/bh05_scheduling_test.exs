Code.require_file("../../bh-05/scheduling-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.SchedulingTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.{SchedulingFixtures, RootRendererPort}
  alias BlazeX.Component.{Input, LocalView, NestedTable, ScheduledView}
  alias BlazeX.Renderer.{Headless, Session}

  setup do
    %{supervisor: start_supervised!(LocalView.Supervisor)}
  end

  defp start(context, root \\ "schedule") do
    state =
      start_supervised!({Agent, fn -> %{accepted: nil, pending: nil} end}, id: {root, :renderer})

    graph = start_supervised!({Agent, &SchedulingFixtures.graph/0}, id: {root, :graph})
    config = %{observer: self(), state: state, graph: graph}

    {:ok, handle} =
      ScheduledView.start(
        context.supervisor,
        SchedulingFixtures.spec(root),
        SchedulingFixtures.ports(config),
        SchedulingFixtures.policy()
      )

    assert_receive {:root_submission, mount, candidate}, 1000
    assert candidate.token.output == SchedulingFixtures.oracle(root, 0)
    context = Map.merge(context, %{config: config, handle: handle, root: root})
    commit(context, mount)
    context
  end

  defp snapshot(context) do
    {:ok, value} = LocalView.inspect_root(context.supervisor, context.handle)
    assert Input.portable?(value)
    value
  end

  defp commit(context, correlation) do
    :ok = RootRendererPort.commit(context.config, correlation)

    :ok =
      LocalView.acknowledge(context.supervisor, context.handle, %{
        correlation: correlation,
        result: :committed
      })
  end

  defp enqueue(context, n, changes \\ %{}),
    do:
      ScheduledView.enqueue(
        context.supervisor,
        context.handle,
        SchedulingFixtures.envelope(context.root, n, changes)
      )

  defp observations(acc \\ []) do
    receive do
      {:root_observation, record} ->
        assert Input.portable?(record)
        observations(acc ++ [record])
    after
      0 -> acc
    end
  end

  test "overproducer stress retains exact FIFO outcomes and raw samples at the 256 bound",
       context do
    context = start(context)
    {:ok, _} = enqueue(context, 1)
    assert_receive {:root_submission, first, _}, 1000

    samples =
      Enum.reduce(2..256, [1], fn n, samples ->
        assert {:ok, %{receipt: ^n}} = enqueue(context, n, %{supersedable: n == 256})
        samples ++ [snapshot(context).scheduling.depth]
      end)

    assert {:ok, %{receipt: 257}} = enqueue(context, 257, %{supersedable: true})
    assert {:error, :overload} = enqueue(context, 258)
    samples = samples ++ [snapshot(context).scheduling.depth]
    assert Enum.max(samples) == 256
    commit(context, first)

    Enum.each(2..256, fn count ->
      assert_receive {:root_submission, correlation, candidate}, 1000
      assert candidate.token.output == SchedulingFixtures.oracle(context.root, count)
      commit(context, correlation)
    end)

    final = snapshot(context)
    assert final.scheduling.depth == 0 and final.scheduling.maximum == 256
    assert final.scheduling.coalesced == 1 and final.scheduling.rejected == 1
    {:ok, oracle} = Session.mount(Headless, SchedulingFixtures.oracle(context.root, 256))
    actual = RootRendererPort.snapshot(context.config).artifact.value
    expected = oracle.artifact.value

    assert Map.drop(Map.from_struct(actual), [:revision, :digest]) ==
             Map.drop(Map.from_struct(expected), [:revision, :digest])

    outcomes =
      observations()
      |> Enum.filter(&(&1.event == :work_outcome))
      |> Enum.map(&{&1.work.receipt, &1.result})

    assert Enum.sort(outcomes) ==
             Enum.map(1..257, &{&1, if(&1 == 256, do: :coalesced, else: :committed)})

    assert Enum.filter(outcomes, &(elem(&1, 1) == :committed)) |> Enum.map(&elem(&1, 0)) ==
             Enum.to_list(1..255) ++ [257]

    IO.puts("SCHEDULING_SAMPLES " <> Enum.join(samples ++ [0], ","))
    IO.puts("SCHEDULING_SAMPLE_SHA256 " <> NestedTable.digest(samples ++ [0]))
    IO.puts("SCHEDULING_TRACE_SHA256 " <> NestedTable.digest(outcomes))

    IO.puts(
      "SCHEDULING_OUTCOMES " <>
        Enum.map_join(outcomes, ",", fn {receipt, result} -> "#{receipt}:#{result}" end)
    )

    IO.puts("SCHEDULING_FINAL_STATE_SHA256 " <> final.accepted.final_digest)
  end

  test "blocked root does not prevent a sibling from committing messages and events", context do
    first = start(context, "first")
    second = start(context, "second")
    {:ok, _} = enqueue(first, 1)
    assert_receive {:root_submission, blocked, _}, 1000

    for {n, changes} <- [
          {1,
           %{
             class: :message,
             name: "tick",
             route: :child,
             target: SchedulingFixtures.child(second.root)
           }},
          {2, %{revision: 2}},
          {3,
           %{
             revision: 3,
             class: :message,
             producer: "child",
             sequence: 1,
             name: "tick",
             source: SchedulingFixtures.child(second.root),
             route: :parent
           }}
        ] do
      {:ok, _} = enqueue(second, n, changes)
      assert_receive {:root_submission, correlation, _}, 1000
      assert correlation.root == second.root
      commit(second, correlation)
    end

    assert snapshot(first).pending == blocked
    assert snapshot(first).accepted.correlation.revision == 1
    assert snapshot(second).accepted.correlation.revision == 4
    commit(first, blocked)
  end

  test "nested removal cancels owned timer and queued child message after accepted update",
       context do
    context = start(context)
    child = SchedulingFixtures.child(context.root)

    {:ok, _} =
      enqueue(context, 1, %{
        class: :timer,
        producer: "child",
        source: child,
        target: child,
        name: "tick",
        timer: %{operation: :start, id: "owned", delay: 60000, interval: 60000}
      })

    assert_receive {:root_observation,
                    %{event: :work_outcome, work: %{receipt: 1}, result: :committed}},
                   1000

    assert snapshot(context).timers.active == 1
    {:ok, _} = enqueue(context, 1)
    assert_receive {:root_submission, event, _}, 1000

    {:ok, _} =
      enqueue(context, 2, %{
        class: :update,
        name: "props",
        payload: %{props: %{"count" => 5}, slots: %{}}
      })

    {:ok, _} = enqueue(context, 3, %{class: :message, name: "tick", target: child, route: :child})

    Agent.update(context.config.graph, fn config ->
      config = put_in(config, [:graph, "root", :children], [])
      %{config | graph: Map.delete(config.graph, "child")}
    end)

    commit(context, event)
    assert_receive {:root_submission, update, candidate}, 1000
    assert length(candidate.state.components) == 1
    assert snapshot(context).timers.active == 1
    commit(context, update)

    assert_receive {:root_observation,
                    %{event: :work_outcome, work: %{receipt: 4}, result: :canceled}},
                   1000

    final = snapshot(context)
    assert final.timers.active == 0 and final.timers.canceled == 1 and final.scheduling.depth == 0

    IO.puts(
      "SCHEDULING_TIMER_INVENTORY " <>
        Enum.map_join(
          [:active, :canceled, :completed, :rejected],
          ",",
          &"#{&1}=#{Map.fetch!(final.timers, &1)}"
        ) <> ",entries=#{length(final.timers.entries)}"
    )

    refute_receive {:root_submission, _, _}, 30
  end

  test "renderer rejection, replay and bad target preserve accepted semantic and rendered state",
       context do
    context = start(context)
    old = snapshot(context).accepted
    rendered = RootRendererPort.snapshot(context.config)
    {:ok, _} = enqueue(context, 1)
    assert_receive {:root_submission, event, _}, 1000
    assert {:error, :stale_sequence} = enqueue(context, 1)
    assert {:error, :invalid_ingress} = enqueue(context, 2, %{payload: %{"delta" => "bad"}})

    assert {:error, :invalid_ingress} =
             enqueue(context, 2, %{target: %{root: "foreign", path: [], generation: 1}})

    :ok = RootRendererPort.cancel(context.config, event)

    assert {:error, :renderer_rejected} =
             LocalView.acknowledge(context.supervisor, context.handle, %{
               correlation: event,
               result: :rolled_back
             })

    assert snapshot(context).accepted == old
    assert RootRendererPort.snapshot(context.config) == rendered

    assert {:error, :stale} =
             LocalView.acknowledge(context.supervisor, context.handle, %{
               correlation: event,
               result: :committed
             })
  end

  test "one-shot and repeating ticks use semantic callbacks and cancellation rolls back headless work",
       context do
    context = start(context)

    {:ok, %{receipt: 1}} =
      enqueue(context, 1, %{
        class: :timer,
        name: "tick",
        timer: %{operation: :start, id: "once", delay: 10, interval: nil}
      })

    assert_receive {:root_submission, once, candidate}, 1000
    assert candidate.token.output == SchedulingFixtures.oracle(context.root, 1)
    commit(context, once)
    assert snapshot(context).timers.completed == 1

    {:ok, %{receipt: 3}} =
      enqueue(context, 2, %{
        class: :timer,
        revision: 2,
        name: "tick",
        timer: %{operation: :start, id: "repeat", delay: 10, interval: 10}
      })

    assert_receive {:root_submission, repeated, candidate}, 1000
    assert candidate.token.output == SchedulingFixtures.oracle(context.root, 2)
    commit(context, repeated)
    rendered = RootRendererPort.snapshot(context.config)
    assert_receive {:root_submission, canceled, candidate}, 1000
    assert candidate.token.output == SchedulingFixtures.oracle(context.root, 3)

    {:ok, %{receipt: 6}} =
      enqueue(context, 3, %{
        class: :timer,
        revision: 3,
        name: "tick",
        timer: %{operation: :cancel, id: "repeat"}
      })

    assert_receive {:root_observation,
                    %{event: :work_outcome, work: %{receipt: 5}, result: :canceled}},
                   1000

    assert snapshot(context).timers.active == 0
    assert snapshot(context).accepted.correlation == repeated
    assert RootRendererPort.snapshot(context.config) == rendered

    assert {:error, :stale} =
             LocalView.acknowledge(context.supervisor, context.handle, %{
               correlation: canceled,
               result: :committed
             })

    refute_receive {:root_submission, _, _}, 30
  end
end
