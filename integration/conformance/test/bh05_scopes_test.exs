Code.require_file("../../bh-05/scope-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.ScopesTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.{ScopeFixtures, RootRendererPort}

  alias BlazeX.Component.{
    ComponentRegistry,
    Input,
    LocalView,
    NestedTable,
    ScheduledView,
    ScopedContext,
    ScopedView
  }

  alias BlazeX.Renderer.{Headless, Session}

  setup do
    %{supervisor: start_supervised!(LocalView.Supervisor)}
  end

  defp start(context, root \\ "scope", mode \\ :tracked) do
    state = start_supervised!({Agent, fn -> %{accepted: nil, pending: nil} end}, id: root)
    renderer = %{observer: self(), state: state}
    config = ScopeFixtures.config(root, mode)

    {:ok, handle} =
      ScheduledView.start(
        context.supervisor,
        ScopeFixtures.spec(root),
        ScopeFixtures.ports(config, renderer),
        ScopeFixtures.policy()
      )

    c = Map.merge(context, %{root: root, config: config, renderer: renderer, handle: handle})
    assert_receive {:root_submission, mount, candidate}, 1000
    assert candidate.token.output == ScopeFixtures.oracle("old", root)
    commit(c, mount)
    c
  end

  defp commit(c, correlation) do
    :ok = RootRendererPort.commit(c.renderer, correlation)

    :ok =
      LocalView.acknowledge(c.supervisor, c.handle, %{
        correlation: correlation,
        result: :committed
      })
  end

  defp snapshot(c) do
    {:ok, snapshot} = LocalView.inspect_root(c.supervisor, c.handle)
    assert Input.portable?(snapshot)
    snapshot
  end

  defp change(c, revision, providers),
    do: ScopedView.change(c.supervisor, c.handle, 1, revision, providers)

  test "contextual slots stay distinct and tracked invalidations match canonical order and independent oracle",
       context do
    c = start(context)
    {:ok, _} = change(c, 1, [ScopeFixtures.provider("new")])
    assert_receive {:root_submission, provider_commit, candidate}, 1000
    assert candidate.token.output == ScopeFixtures.oracle("old")
    consumers = candidate.token.scope.context.pending
    assert length(consumers) == 3 and snapshot(c).scheduling.reserved == 3
    commit(c, provider_commit)

    {trace, final} =
      Enum.reduce(consumers, {[], nil}, fn consumer, {trace, _} ->
        assert_receive {:root_submission, update, candidate}, 1000

        assert Enum.find(candidate.token.scope.context.bindings, &(&1.consumer == consumer)).value ==
                 "new"

        commit(c, update)
        {trace ++ [consumer.path], candidate}
      end)

    assert final.token.output == ScopeFixtures.oracle("new")
    assert final.token.scope.context.pending == []
    assert length(ScopedContext.snapshot(final.token.scope.context).subscriptions) == 3
    {:ok, oracle} = Session.mount(Headless, ScopeFixtures.oracle("new"))
    actual = RootRendererPort.snapshot(c.renderer).artifact.value

    assert Map.drop(Map.from_struct(actual), [:revision, :digest]) ==
             Map.drop(Map.from_struct(oracle.artifact.value), [:revision, :digest])

    IO.puts("SCOPE_INVALIDATION_ORDER root,child,pure")
    IO.puts("SCOPE_TRACE_SHA256 " <> NestedTable.digest(trace))
    IO.puts("SCOPE_FINAL_STATE_SHA256 " <> final.final_digest)
    IO.puts("SCOPE_SUBSCRIPTIONS 3,3,3,3")
  end

  test "nearest provider removal and dynamic replacement clean subscriptions without cross-root leakage",
       context do
    c = start(context)
    sibling = start(context, "sibling")
    child = %{ScopeFixtures.owner() | path: [{"child", "fixture", :child, "child"}]}

    {:ok, _} =
      change(c, 1, [ScopeFixtures.provider("old"), ScopeFixtures.provider("nested", child)])

    assert_receive {:root_submission, provider, _}, 1000
    commit(c, provider)
    assert_receive {:root_submission, child_update, candidate}, 1000

    assert Enum.find(candidate.token.scope.context.bindings, &(&1.consumer == child)).value ==
             "nested"

    commit(c, child_update)
    assert {:error, _} = change(sibling, 2, [ScopeFixtures.provider("foreign")])
    {:ok, _} = ScopedView.select(c.supervisor, c.handle, 1, 2, 1, %{"child" => "alternate"})
    assert_receive {:root_submission, replacement, candidate}, 1000
    assert Enum.all?(candidate.token.scope.context.bindings, &(&1.consumer != child))
    assert hd(candidate.token.scope.context.removed).owner == child
    assert candidate.token.output == ScopeFixtures.oracle("old", "scope", 1, "alternate")
    commit(c, replacement)
    assert snapshot(sibling).accepted.correlation.revision == 1
    metadata = ComponentRegistry.metadata(c.config.scope.registry)

    assert Input.portable?(metadata) and
             Enum.all?(metadata.entries, &(not Map.has_key?(&1, :module)))

    IO.puts("SCOPE_REGISTRY_SHA256 " <> NestedTable.digest(metadata))
  end

  test "fixed mutation forged IDs and renderer rejection preserve accepted state", context do
    c = start(context, "fixed", :fixed)
    before = snapshot(c).accepted
    {:ok, _} = change(c, 1, [ScopeFixtures.provider("no", ScopeFixtures.owner("fixed"))])
    refute_receive {:root_submission, _, _}, 20
    assert snapshot(c).accepted == before
    {:ok, _} = ScopedView.select(c.supervisor, c.handle, 1, 1, 1, %{"pure" => "Elixir.System"})
    refute_receive {:root_submission, _, _}, 20
    assert snapshot(c).accepted == before
    {:ok, _} = ScopedView.select(c.supervisor, c.handle, 1, 1, 1, %{"child" => "alternate"})
    assert_receive {:root_submission, pending, _}, 1000
    :ok = RootRendererPort.cancel(c.renderer, pending)

    assert {:error, :renderer_rejected} =
             LocalView.acknowledge(c.supervisor, c.handle, %{
               correlation: pending,
               result: :rolled_back
             })

    assert snapshot(c).accepted == before and snapshot(c).scheduling.depth == 0
  end

  test "explicit root replacement rebinds templates and disposal rejects old scope updates",
       context do
    c = start(context)
    {:ok, replacement} = LocalView.replace(c.supervisor, c.handle, 1, ScopeFixtures.spec())
    assert_receive {:root_submission, ^replacement, candidate}, 1000
    assert candidate.token.scope.context.generation == 2
    assert Enum.all?(candidate.token.scope.context.providers, &(&1.owner.generation == 2))
    assert candidate.token.output == ScopeFixtures.oracle("old", "scope", 2)
    commit(c, replacement)
    assert {:error, _} = change(c, 1, [ScopeFixtures.provider("stale")])
    {:ok, disposal} = LocalView.stop(c.supervisor, c.handle)
    commit(c, disposal)
    assert snapshot(c).status == :disposed
    assert {:error, _} = ScopedView.change(c.supervisor, c.handle, 2, 1, [])
    IO.puts("SCOPE_CLEANUP replaced=1,disposed=1,late_rejected=1")
  end
end
