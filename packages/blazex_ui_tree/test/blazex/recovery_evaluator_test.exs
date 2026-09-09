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
  end

  def config,
    do: %{
      automatic: false,
      user: true,
      host: true,
      changed: true,
      backoff_ms: 100,
      port_timeout_ms: 50
    }

  def ports(renderer \\ {F.Port, self()}),
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
        %{F.spec() | component: Broken},
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
    assert :ok = LocalView.stop(supervisor, handle)

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
        %{F.spec() | root: "sibling", instance: "sibling"},
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
  end

  test "retry requires declared source and exact failed generation and fingerprint" do
    supervisor = start_supervised!(LocalView.Supervisor)

    {:ok, handle} =
      RecoveryView.start(
        supervisor,
        %{F.spec() | component: Broken},
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
               RecoveryView.retry(supervisor, handle, generation, digest, source, F.spec())
    end

    assert {:ok, %{generation: 2}} =
             RecoveryView.retry(supervisor, handle, 1, fingerprint, :user, F.spec())

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
        %{F.spec() | component: Broken},
        ports({Unavailable, nil}),
        F.policy(),
        config()
      )

    Process.sleep(30)
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.status == :failed and snapshot.recovery.failure.fallback == :static
    assert snapshot.attempt <= 2
  end
end
