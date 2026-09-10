Code.require_file("scoped_evaluator_test.exs", __DIR__)

defmodule BlazeX.RecoveryEvaluatorTest do
  use ExUnit.Case, async: true
  alias BlazeX.ScopedEvaluatorTest, as: F
  alias BlazeX.Component.{Input, LocalView, RecoveryView}
  alias BlazeX.UITree.{IntentSet, RecoveryEvaluator, ScopedEvaluator}

  defmodule Broken do
    def __blazex_component__, do: BlazeX.ScopedEvaluatorTest.Root.__blazex_component__()
    def mount(_), do: {:state, 0}
    def render(_), do: raise("private-secret-error")
    def terminate(_), do: :ok
  end

  defmodule Unavailable do
    def submit(_, _, _), do: {:error, :unavailable}
    def cancel(_, _), do: :ok
    def dispose(_, _), do: :ok
    def force_cleanup(_, _), do: :ok
  end

  defmodule Port do
    def submit(pid, correlation, candidate),
      do: BlazeX.ScopedEvaluatorTest.Port.submit(pid, correlation, candidate)

    def cancel(_, _), do: :ok
    def dispose(_, _), do: :ok
    def force_cleanup(_, _), do: :ok
  end

  def spec, do: %{F.spec() | fallback: {:static, "recovery"}}

  def config,
    do: %{
      automatic: false,
      user: true,
      host: true,
      changed: true,
      backoff_ms: 100,
      port_timeout_ms: 50
    }

  def ports(renderer \\ {Port, self()}),
    do: %{
      evaluator: {RecoveryEvaluator, {{ScopedEvaluator, F.config()}, 50}},
      renderer: renderer,
      host: {F.Port, self()}
    }

  test "callback failure commits callback-independent accessible fallback and preserves sibling" do
    supervisor = start_supervised!(LocalView.Supervisor)

    {:ok, handle} =
      RecoveryView.start(
        supervisor,
        %{spec() | component: Broken},
        ports(),
        F.policy(),
        config()
      )

    assert_receive {:submission, failure, candidate}, 1000
    assert failure.operation == :failure
    assert IntentSet.validate(candidate.token.output) == :ok
    assert hd(candidate.token.output.accessibility).role == :status
    assert hd(candidate.token.output.focus).auto_focus
    assert Input.portable?(candidate.state.failure)
    refute inspect(candidate.state.failure) =~ "private-secret"

    assert :ok =
             LocalView.acknowledge(supervisor, handle, %{correlation: failure, result: :committed})

    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.status == :failed and snapshot.recovery.failure.fallback == :committed
    assert {:error, _} = LocalView.enqueue(supervisor, handle, %{})

    sibling_config =
      put_in(F.config(), [:scope, :providers], [
        %{owner: %{F.owner() | root: "sibling"}, name: "locale", value: "old"}
      ])

    sibling_ports = %{
      ports()
      | evaluator: {RecoveryEvaluator, {{ScopedEvaluator, sibling_config}, 50}}
    }

    {:ok, sibling} =
      RecoveryView.start(
        supervisor,
        %{spec() | root: "sibling", instance: "sibling"},
        sibling_ports,
        F.policy(),
        config()
      )

    assert_receive {:submission, sibling_mount, _}, 1000
    assert sibling_mount.root == "sibling" and sibling_mount.operation == :mount

    assert :ok =
             LocalView.acknowledge(supervisor, sibling, %{
               correlation: sibling_mount,
               result: :committed
             })

    assert {:ok, %{status: :ready}} = LocalView.inspect_root(supervisor, sibling)
    assert {:ok, ^snapshot} = LocalView.inspect_root(supervisor, handle)
    assert :ok = LocalView.stop(supervisor, handle)
    assert :ok = LocalView.stop(supervisor, handle)
  end

  test "retry requires declared source and exact failed generation and fingerprint" do
    supervisor = start_supervised!(LocalView.Supervisor)

    {:ok, handle} =
      RecoveryView.start(
        supervisor,
        %{spec() | component: Broken},
        ports(),
        F.policy(),
        config()
      )

    assert_receive {:submission, failure, candidate}, 1000
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: failure, result: :committed})
    fingerprint = candidate.state.failure.fingerprint

    for {generation, digest, source} <- [
          {2, fingerprint, :user},
          {1, "forged", :user},
          {1, fingerprint, :automatic}
        ] do
      assert {:error, _} =
               RecoveryView.retry(supervisor, handle, generation, digest, source, spec())
    end

    assert {:ok, %{generation: 2}} =
             RecoveryView.retry(supervisor, handle, 1, fingerprint, :user, spec())

    assert_receive {:submission, mount, fresh}, 1000
    assert mount.generation == 2 and mount.operation == :mount
    assert hd(fresh.state.components).state == {:present, 0}

    assert {:error, :stale} =
             LocalView.acknowledge(supervisor, handle, %{correlation: failure, result: :committed})

    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    assert {:ok, %{status: :ready}} = LocalView.inspect_root(supervisor, handle)
  end

  test "renderer unavailable retains static fallback without recursive failure" do
    supervisor = start_supervised!(LocalView.Supervisor)

    {:ok, handle} =
      RecoveryView.start(
        supervisor,
        %{spec() | component: Broken},
        ports({Unavailable, nil}),
        F.policy(),
        config()
      )

    Process.sleep(30)
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.status == :failed and snapshot.recovery.failure.fallback == :static
    assert snapshot.attempt <= 2
  end

  test "renderer rejection and commit deadline converge on failure then static fallback" do
    supervisor = start_supervised!(LocalView.Supervisor)

    for {instance, outcome} <- [{"reject", :rejected}, {"timeout", :timeout}] do
      {:ok, handle} =
        RecoveryView.start(
          supervisor,
          %{spec() | instance: instance, timeout_ms: 100},
          ports(),
          F.policy(),
          config()
        )

      assert_receive {:submission, mount, _}, 1000

      if outcome == :rejected do
        LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :rejected})
      end

      assert_receive {:submission, failure, _}, 1000
      assert failure.operation == :failure
      Process.sleep(150)
      {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
      assert snapshot.status == :failed
      assert snapshot.recovery.failure.fallback == :static
      assert snapshot.recovery.failure.static_fallback == "recovery"
      assert snapshot.recovery.cleanup.unresolved == 0
      assert :ok = LocalView.stop(supervisor, handle)
    end
  end

  test "persistent failure has exactly three automatic fresh-generation restarts then terminal fallback" do
    supervisor = start_supervised!(LocalView.Supervisor)

    {:ok, handle} =
      RecoveryView.start(supervisor, %{spec() | component: Broken}, ports(), F.policy(), %{
        config()
        | automatic: true
      })

    fingerprints =
      for generation <- 1..4 do
        assert_receive {:submission, failure, candidate}, 1000
        assert failure.generation == generation and failure.operation == :failure

        :ok =
          LocalView.acknowledge(supervisor, handle, %{correlation: failure, result: :committed})

        candidate.state.failure.fingerprint
      end

    Process.sleep(150)
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.status == :failed
    assert snapshot.recovery.restart.maximum == 3
    assert snapshot.recovery.restart.terminal == :restart_intensity

    assert Enum.map(snapshot.recovery.restart.attempts, & &1.decision) == [
             :admitted,
             :admitted,
             :admitted,
             :restart_intensity
           ]

    assert Enum.uniq(fingerprints) |> length() == 1
    refute_receive {:submission, _, _}, 150
  end

  test "hard worker crash contains one root and cleanup releases its accepted owners" do
    supervisor = start_supervised!(LocalView.Supervisor)
    {:ok, handle} = RecoveryView.start(supervisor, spec(), ports(), F.policy(), config())
    assert_receive {:submission, mount, _}, 1000
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    [{_, guardian, _, _}] = Supervisor.which_children(supervisor)
    Process.exit(:sys.get_state(guardian).worker, :kill)
    assert_receive {:submission, failure, candidate}, 1000
    assert candidate.state.failure.code == :crashed
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: failure, result: :committed})
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    rows = List.flatten(snapshot.recovery.cleanup.pages)
    assert Enum.map(Enum.filter(rows, &(&1.kind == :component)), &length(&1.owner.path)) == [1, 0]
    assert snapshot.recovery.cleanup.unresolved == 0
  end

  test "replacement and repeated shutdown clean each generation and reject old scope work" do
    supervisor = start_supervised!(LocalView.Supervisor)
    {:ok, handle} = RecoveryView.start(supervisor, spec(), ports(), F.policy(), config())
    assert_receive {:submission, mount, _}, 1000
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    assert {:ok, replace} = LocalView.replace(supervisor, handle, 1, spec())
    assert_receive {:submission, ^replace, candidate}, 1000
    assert replace.generation == 2
    assert Enum.all?(candidate.token.scope.context.bindings, &(&1.consumer.generation == 2))
    {:ok, pending} = LocalView.inspect_root(supervisor, handle)

    assert Enum.map(List.flatten(pending.recovery.cleanup.pages), & &1.kind) == [
             :component,
             :component,
             :renderer
           ]

    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: replace, result: :committed})

    assert {:error, _} =
             BlazeX.Component.ScopedView.change(supervisor, handle, 1, 1, F.providers("stale"))

    assert {:error, :stale} =
             LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})

    assert :ok = LocalView.stop(supervisor, handle)
    {:ok, disposed} = LocalView.inspect_root(supervisor, handle)
    assert disposed.status == :disposed and disposed.recovery.cleanup.unresolved == 0
    assert :ok = LocalView.stop(supervisor, handle)
    assert {:ok, ^disposed} = LocalView.inspect_root(supervisor, handle)
  end
end
