Code.require_file("../../bh-05/action-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.ActionsTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.{ActionFixtures, RootRendererPort}
  alias BlazeX.Component.{Action, ActionView, Input, LocalView, NestedTable, ScheduledView}
  alias BlazeX.Renderer.{Headless, Session}

  setup do
    %{supervisor: start_supervised!(LocalView.Supervisor)}
  end

  defp start(context, mode \\ :accept, limit \\ 16) do
    root = "actions-#{mode}"

    state =
      start_supervised!({Agent, fn -> %{accepted: nil, pending: nil} end}, id: {root, :renderer})

    graph = start_supervised!({Agent, &ActionFixtures.graph/0}, id: {root, :graph})
    config = %{observer: self(), state: state, graph: graph, mode: mode}

    manifest =
      ActionFixtures.manifest()
      |> put_in([:effects, "read", :lease_limit], limit)
      |> put_in([:effects, "read", :lease_kind], if(limit == 0, do: nil, else: "subscription"))

    {:ok, handle} =
      ActionView.start(
        context.supervisor,
        ActionFixtures.spec(root),
        ActionFixtures.ports(config),
        ActionFixtures.policy(),
        manifest,
        ActionFixtures.provider(config)
      )

    context = Map.merge(context, %{config: config, root: root, handle: handle})
    assert_receive {:root_submission, mount, candidate}, 1000
    assert candidate.token.output == ActionFixtures.oracle(root, 0)
    commit(context, mount)
    context
  end

  defp commit(context, correlation) do
    :ok = RootRendererPort.commit(context.config, correlation)

    :ok =
      LocalView.acknowledge(context.supervisor, context.handle, %{
        correlation: correlation,
        result: :committed
      })
  end

  defp snapshot(context) do
    {:ok, value} = LocalView.inspect_root(context.supervisor, context.handle)
    assert Input.portable?(value)
    value
  end

  defp event(context, n, op \\ "request", who \\ "root") do
    revision = snapshot(context).accepted.correlation.revision

    ScheduledView.event(
      context.supervisor,
      context.handle,
      ActionFixtures.envelope(context.root, n, revision, op, n, who)
    )
  end

  defp request(context, n, op \\ "request", who \\ "root") do
    {:ok, _} = event(context, n, op, who)
    assert_receive {:root_submission, correlation, _}, 1000
    commit(context, correlation)
    assert_receive {:action_submission, packet}, 1000
    packet
  end

  defp deliver(context, packet, status, value, leases \\ []) do
    {:ok, result} = Action.result(packet.correlation, status, value, leases)
    :ok = ActionView.result(context.supervisor, context.handle, result)
    assert_receive {:root_submission, correlation, candidate}, 1000
    {result, correlation, candidate}
  end

  test "delayed results cross the commit barrier and match an independent headless oracle",
       context do
    context = start(context)
    {:ok, _} = event(context, 1)
    assert_receive {:root_submission, event, _}, 1000
    refute_receive {:action_submission, _}, 20
    commit(context, event)
    assert_receive {:action_submission, packet}, 1000
    assert snapshot(context).actions.pending == 1
    assert snapshot(context).scheduling.depth == 1
    {result, response, candidate} = deliver(context, packet, :completed, %{"value" => 9})
    assert candidate.token.output == ActionFixtures.oracle(context.root, 9)

    assert {:error, :invalid_or_stale_result} =
             ActionView.result(context.supervisor, context.handle, result)

    commit(context, response)
    {:ok, oracle} = Session.mount(Headless, ActionFixtures.oracle(context.root, 9))
    actual = RootRendererPort.snapshot(context.config).artifact.value

    assert Map.drop(Map.from_struct(actual), [:revision, :digest]) ==
             Map.drop(Map.from_struct(oracle.artifact.value), [:revision, :digest])

    final = snapshot(context)
    assert final.actions.pending == 0 and final.scheduling.depth == 0
    IO.puts("ACTION_TRACE completed=1,pending=0,leases=0,replayed=0")
    IO.puts("ACTION_FINAL_STATE_SHA256 " <> final.accepted.final_digest)
    refute_receive {:action_submission, _}, 20
  end

  test "deny fallback disconnection failure and timeout enter typed callbacks", context do
    for mode <- [:deny, :fallback, :disconnect] do
      context = start(context, mode)
      {:ok, _} = event(context, 1)
      assert_receive {:root_submission, event, _}, 1000
      commit(context, event)

      if mode == :fallback do
        assert_receive {:action_submission, packet}, 1000
        {_, response, _} = deliver(context, packet, :failed, %{"code" => "unavailable"})
        commit(context, response)
        assert snapshot(context).actions.totals.failed == 1
      else
        if mode == :disconnect, do: assert_receive({:action_submission, _}, 1000)
        assert_receive {:root_submission, response, _}, 1000
        commit(context, response)
        status = if mode == :deny, do: :denied, else: :disconnected
        assert snapshot(context).actions.totals[status] == 1
      end
    end

    context = start(context, :timeout)
    packet = request(context, 1, "timeout")
    assert_receive {:action_cancel, %{correlation: correlation}}, 1000
    assert correlation == packet.correlation
    assert_receive {:root_submission, response, _}, 1000
    commit(context, response)
    {:ok, late} = Action.result(packet.correlation, :completed, %{"value" => 8})
    assert {:error, _} = ActionView.result(context.supervisor, context.handle, late)
    assert snapshot(context).actions.totals.timed_out == 1
  end

  test "the 129th pending request rejects before rendering and retains exact raw pending samples",
       context do
    context = start(context, :pending, 0)

    samples =
      Enum.map(1..128, fn n ->
        request(context, n)
        snapshot(context).actions.pending
      end)

    old = snapshot(context).accepted
    assert {:ok, _} = event(context, 129)
    refute_receive {:root_submission, _, _}, 20
    final = snapshot(context)
    assert final.actions.pending == 128 and final.accepted == old
    assert final.scheduling.depth == 128
    IO.puts("ACTION_PENDING_SAMPLES " <> Enum.join(samples ++ [128], ","))
    IO.puts("ACTION_PENDING_SHA256 " <> NestedTable.digest(samples ++ [128]))
  end

  test "512 live leases reject excess acquisition and shutdown releases the full bounded inventory",
       context do
    context = start(context, :leases)

    samples =
      Enum.map(1..32, fn n ->
        packet = request(context, n)

        {_, response, _} =
          deliver(
            context,
            packet,
            :completed,
            %{"value" => n},
            Enum.map(1..16, &"lease_#{n}_#{&1}")
          )

        commit(context, response)
        snapshot(context).actions.leases
      end)

    old = snapshot(context).accepted
    assert {:ok, _} = event(context, 33)
    refute_receive {:root_submission, _, _}, 20
    assert snapshot(context).accepted == old and snapshot(context).actions.leases == 512
    {:ok, disposal} = LocalView.stop(context.supervisor, context.handle, :shutdown)
    for _ <- 1..512, do: assert_receive({:action_release, _}, 1000)
    commit(context, disposal)
    assert snapshot(context).status == :disposed and snapshot(context).actions.leases == 0
    IO.puts("ACTION_LEASE_SAMPLES " <> Enum.join(samples ++ [512, 0], ","))
    IO.puts("ACTION_LEASE_SHA256 " <> NestedTable.digest(samples ++ [512, 0]))
  end

  test "nested results use handle_info and removal cancels requests and transferred leases",
       context do
    context = start(context, :removal)
    packet = request(context, 1)
    {_, response, _} = deliver(context, packet, :completed, %{"value" => 1}, ["lease"])
    commit(context, response)
    {:ok, _} = event(context, 2, "transfer")
    assert_receive {:root_submission, transfer, _}, 1000
    commit(context, transfer)

    assert hd(hd(snapshot(context).actions.inventory_pages)).owner ==
             ActionFixtures.child(context.root)

    packet = request(context, 1, "request", "child")
    {_, response, candidate} = deliver(context, packet, :completed, %{"value" => 7})
    assert candidate.token.output == ActionFixtures.oracle(context.root, 2, 7)
    commit(context, response)
    pending = request(context, 2, "request", "child")

    Agent.update(context.config.graph, fn graph ->
      graph = put_in(graph, [:graph, "root", :children], [])
      %{graph | graph: Map.delete(graph.graph, "child")}
    end)

    revision = snapshot(context).accepted.correlation.revision

    envelope =
      ActionFixtures.envelope(context.root, 3, revision, "request", 3)
      |> Map.merge(%{class: :update, name: "props", payload: %{props: %{}, slots: %{}}})

    {:ok, _} = ScheduledView.enqueue(context.supervisor, context.handle, envelope)
    assert_receive {:root_submission, removal, _}, 1000
    commit(context, removal)
    assert_receive {:action_cancel, %{correlation: canceled}}, 1000
    assert canceled == pending.correlation
    assert_receive {:action_release, released}, 1000
    assert released.resource.owner.path == ActionFixtures.child(context.root).path
    assert snapshot(context).actions.pending == 0 and snapshot(context).actions.leases == 0
    {:ok, result} = Action.result(pending.correlation, :completed, %{"value" => 99})
    assert {:error, _} = ActionView.result(context.supervisor, context.handle, result)
  end

  test "rejected result rendering releases acquisitions while explicit release failures are lost",
       context do
    context = start(context, :lost)
    packet = request(context, 1)
    {_, response, _} = deliver(context, packet, :completed, %{"value" => 9}, ["lease"])
    :ok = RootRendererPort.cancel(context.config, response)

    assert {:error, :renderer_rejected} =
             LocalView.acknowledge(context.supervisor, context.handle, %{
               correlation: response,
               result: :rolled_back
             })

    assert_receive {:action_release, _}, 1000
    assert snapshot(context).actions.totals.lost == 1
    packet = request(context, 2)
    {_, response, _} = deliver(context, packet, :completed, %{"value" => 9}, ["lease"])
    commit(context, response)
    {:ok, _} = event(context, 3, "release")
    assert_receive {:root_submission, release, _}, 1000
    refute_receive {:action_release, _}, 20
    commit(context, release)
    assert_receive {:action_release, _}, 1000
    assert snapshot(context).actions.leases == 0 and snapshot(context).actions.totals.lost == 2
  end

  test "future command adapter denies untrusted intent without reverting committed local state",
       context do
    context = start(context, :command)
    packet = request(context, 1, "command")
    assert packet.trust == :untrusted_client and length(packet.server_requirements) == 6
    assert_receive {:root_submission, denial, candidate}, 1000
    assert candidate.token.output == ActionFixtures.oracle(context.root, 1)
    commit(context, denial)
    assert snapshot(context).actions.totals.denied == 1
    refute Map.has_key?(packet, :transport)
    refute_receive {:action_submission, _}, 20
  end

  test "root correlations isolate requests and runtime loss rejects late and post-disposal results",
       context do
    first = start(context, :first)
    second = start(context, :second)
    packet = request(first, 1)
    {:ok, result} = Action.result(packet.correlation, :completed, %{"value" => 9})
    assert {:error, _} = ActionView.result(second.supervisor, second.handle, result)
    assert {:error, :port_failed} = LocalView.runtime_loss(first.supervisor, first.handle)
    assert_receive {:action_cancel, %{correlation: canceled}}, 1000
    assert canceled == packet.correlation
    assert snapshot(first).actions.pending == 0
    assert {:error, _} = ActionView.result(first.supervisor, first.handle, result)
    :ok = LocalView.stop(first.supervisor, first.handle)
    assert {:error, _} = ActionView.result(first.supervisor, first.handle, result)
    refute_receive {:action_submission, _}, 20
    assert snapshot(second).status == :ready
  end
end
