Code.require_file("../../bh-05/root-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.RootTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.{RootFixtures, RootRendererPort}
  alias BlazeX.Component.{Input, LocalView, NestedTable}
  alias BlazeX.Renderer.{Headless, Session}

  setup do
    supervisor = start_supervised!(LocalView.Supervisor)
    state = start_supervised!({Agent, fn -> %{accepted: nil, pending: nil} end})
    config = %{observer: self(), state: state}
    %{supervisor: supervisor, config: config, ports: RootFixtures.ports(config)}
  end

  defp start(context, spec \\ RootFixtures.spec()) do
    assert {:ok, handle} = LocalView.start(context.supervisor, spec, context.ports)
    {correlation, candidate} = submitted()
    {handle, correlation, candidate}
  end

  defp submitted do
    assert_receive {:root_submission, correlation, candidate}, 1000
    {correlation, candidate}
  end

  defp inspect_root(context, handle) do
    assert {:ok, snapshot} = LocalView.inspect_root(context.supervisor, handle)
    assert Input.portable?(snapshot)
    snapshot
  end

  defp commit(context, handle, correlation) do
    assert :ok = RootRendererPort.commit(context.config, correlation)

    assert :ok =
             LocalView.acknowledge(context.supervisor, handle, %{
               correlation: correlation,
               result: :committed
             })

    inspect_root(context, handle)
  end

  defp observations(acc \\ []) do
    receive do
      {:root_observation, record} ->
        assert Input.portable?(record)
        observations(acc ++ [record])
    after
      0 -> acc
    end
  end

  test "public supervised script matches independent headless oracle and commit digests",
       context do
    {handle, mount, first} = start(context)
    assert first.token.output == RootFixtures.oracle(1)
    assert inspect_root(context, handle).accepted == nil
    assert RootRendererPort.snapshot(context.config) == nil
    {:ok, oracle} = Session.mount(Headless, RootFixtures.oracle(1))
    mounted = commit(context, handle, mount)
    assert RootRendererPort.snapshot(context.config).artifact == oracle.artifact

    {:ok, update} = LocalView.update(context.supervisor, handle, 1, %{"count" => 3})
    {^update, candidate} = submitted()
    assert candidate.token.output == RootFixtures.oracle(3)
    assert inspect_root(context, handle).accepted == mounted.accepted
    {:ok, oracle} = Session.update(oracle, RootFixtures.oracle(3))
    updated = commit(context, handle, update)
    assert RootRendererPort.snapshot(context.config).artifact == oracle.artifact

    {:ok, noop} = LocalView.update(context.supervisor, handle, 2, %{"count" => 3})
    {^noop, _} = submitted()
    no_change = commit(context, handle, noop)
    assert no_change.accepted.state_digest == updated.accepted.state_digest
    {:ok, oracle} = Session.update(oracle, RootFixtures.oracle(3))

    {:ok, replace} =
      LocalView.replace(context.supervisor, handle, 3, RootFixtures.spec(%{"count" => 9}))

    {^replace, candidate} = submitted()
    assert candidate.token.output == RootFixtures.oracle(9, 2)
    assert inspect_root(context, handle).accepted == no_change.accepted
    {:ok, oracle} = Session.replace(oracle, RootFixtures.oracle(9, 2))
    replaced = commit(context, handle, replace)
    assert RootRendererPort.snapshot(context.config).artifact == oracle.artifact

    {:ok, disposal} = LocalView.stop(context.supervisor, handle, :removal)
    {^disposal, nil} = submitted()
    assert inspect_root(context, handle).status == :stopping
    disposed = commit(context, handle, disposal)
    {:ok, oracle} = Session.dispose(oracle)
    assert RootRendererPort.snapshot(context.config).artifact == oracle.artifact
    assert disposed.status == :disposed and disposed.accepted == replaced.accepted
    assert :ok = LocalView.stop(context.supervisor, handle)

    trace = observations()
    assert Enum.count(trace, &(&1.event == :ready)) == 4
    assert Enum.count(trace, &(&1.event == :disposed)) == 1
    snapshots = [mounted, updated, no_change, replaced, disposed]
    IO.puts("ROOT_SCRIPT_SHA256 " <> NestedTable.digest(snapshots))
    IO.puts("ROOT_TRACE_SHA256 " <> NestedTable.digest(trace))
    IO.puts("ROOT_FINAL_STATE_SHA256 " <> replaced.accepted.final_digest)
  end

  test "callback and semantic failure never submit or promote a candidate", context do
    {handle, mount, _} = start(context)
    accepted = commit(context, handle, mount).accepted

    for fault <- ["update", "render", "semantic", "effect"] do
      assert {:error, :semantic_rejected} =
               LocalView.update(context.supervisor, handle, 1, %{"fault" => fault})

      assert inspect_root(context, handle).accepted == accepted
      refute_receive {:root_submission, _, _}
    end

    refute inspect(observations()) =~ "private_"
  end

  test "renderer rollback preserves both final component and actual headless state", context do
    {handle, mount, _} = start(context)
    first = commit(context, handle, mount)
    old_renderer = RootRendererPort.snapshot(context.config)
    {:ok, update} = LocalView.update(context.supervisor, handle, 1, %{"count" => 5})
    submitted()
    assert :ok = RootRendererPort.cancel(context.config, update)

    assert {:error, :renderer_rejected} =
             LocalView.acknowledge(context.supervisor, handle, %{
               correlation: update,
               result: :rolled_back
             })

    assert inspect_root(context, handle).accepted == first.accepted
    assert RootRendererPort.snapshot(context.config) == old_renderer

    assert {:error, :stale} =
             LocalView.acknowledge(context.supervisor, handle, %{
               correlation: update,
               result: :committed
             })
  end

  test "lost acknowledgement after renderer commit is rolled back before root returns ready",
       context do
    {handle, mount, _} = start(context, %{RootFixtures.spec() | timeout_ms: 100})
    first = commit(context, handle, mount)
    old_renderer = RootRendererPort.snapshot(context.config)
    {:ok, update} = LocalView.update(context.supervisor, handle, 1, %{"count" => 8})
    submitted()
    :ok = RootRendererPort.commit(context.config, update)
    assert RootRendererPort.snapshot(context.config) != old_renderer
    assert inspect_root(context, handle).accepted == first.accepted
    assert_receive {:root_observation, %{event: :rejected, error: :timeout}}, 1000
    assert RootRendererPort.snapshot(context.config) == old_renderer
    assert inspect_root(context, handle).status == :ready
  end

  test "mount rejection and cleanup failure are terminal without false readiness", context do
    {:ok, handle} =
      LocalView.start(context.supervisor, RootFixtures.spec(%{"fault" => "mount"}), context.ports)

    assert_receive {:root_observation, %{event: :failed, error: :semantic_rejected}}, 1000
    assert inspect_root(context, handle).accepted == nil
    spec = %{RootFixtures.spec(%{"fault" => "cleanup"}) | instance: "next"}
    {handle, mount, _} = start(context, spec)
    commit(context, handle, mount)
    {:ok, disposal} = LocalView.stop(context.supervisor, handle)
    submitted()
    :ok = RootRendererPort.commit(context.config, disposal)

    assert {:error, :cleanup_failed} =
             LocalView.acknowledge(context.supervisor, handle, %{
               correlation: disposal,
               result: :committed
             })

    assert inspect_root(context, handle).status == :failed
    assert RootRendererPort.snapshot(context.config).status == :disposed
  end
end
