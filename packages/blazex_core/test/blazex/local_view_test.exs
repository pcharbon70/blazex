defmodule BlazeX.LocalViewTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{LocalView, RootPort}

  defmodule Component do
    use BlazeX.Component,
      role: :root,
      schema: [props: [{"count", [type: :integer, default: 0]}], slots: []]

    def mount(%{props: props}), do: {:state, props}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule Ports do
    def prepare(config, request, _old) do
      if Agent.get(config.settings, &Map.get(&1, :semantic, false)),
        do: {:error, :private_failure},
        else:
          RootPort.candidate(
            request.correlation,
            request.spec.props,
            String.duplicate("a", 64),
            :private_token
          )
    end

    def cleanup(config, _accepted, reason) do
      send(config.observer, {:cleanup, reason})
      Agent.get(config.settings, &Map.get(&1, :cleanup, :ok))
    end

    def submit(config, correlation, candidate) do
      send(config.observer, {:submit, correlation, candidate})
      Agent.get(config.settings, &Map.get(&1, :submit, :ok))
    end

    def cancel(config, correlation) do
      send(config.observer, {:cancel, correlation})
      Agent.get(config.settings, &Map.get(&1, :cancel, :ok))
    end

    def notify(config, record) do
      send(config.observer, {:host, record})
      :ok
    end
  end

  setup do
    supervisor = start_supervised!(LocalView.Supervisor)
    settings = start_supervised!({Agent, fn -> %{} end})
    config = %{observer: self(), settings: settings}
    ports = %{evaluator: {Ports, config}, renderer: {Ports, config}, host: {Ports, config}}

    spec = %{
      root: "r",
      instance: "i",
      owner: "o",
      public_id: "root",
      component: Component,
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 5000
    }

    %{supervisor: supervisor, settings: settings, spec: spec, ports: ports}
  end

  defp mounted(context, spec \\ nil) do
    {:ok, handle} = LocalView.start(context.supervisor, spec || context.spec, context.ports)
    assert_receive {:submit, correlation, candidate}, 1000
    assert :ok == ack(context, handle, correlation)
    {handle, candidate}
  end

  defp ack(context, handle, correlation, result \\ :committed),
    do:
      LocalView.acknowledge(context.supervisor, handle, %{
        correlation: correlation,
        result: result
      })

  defp snapshot(context, handle) do
    assert {:ok, value} = LocalView.inspect_root(context.supervisor, handle)
    value
  end

  test "mount and every update publish final state only at exact commit", context do
    assert {:ok, handle} = LocalView.start(context.supervisor, context.spec, context.ports)
    assert handle == %{root: "r", instance: "i", owner: "o"}
    assert_receive {:submit, correlation, candidate}
    assert snapshot(context, handle).accepted == nil
    assert snapshot(context, handle).status == :awaiting_commit
    assert {:error, :busy} = LocalView.update(context.supervisor, handle, 0, %{})
    assert {:error, :stale} = ack(context, handle, %{correlation | owner: "wrong"})
    assert :ok = ack(context, handle, correlation)
    first = snapshot(context, handle)
    assert first.status == :ready and first.accepted == RootPort.summary(candidate)
    assert {:error, :stale} = ack(context, handle, correlation)
    assert {:ok, update} = LocalView.update(context.supervisor, handle, 1, %{"count" => 2})
    assert_receive {:submit, ^update, next}
    assert snapshot(context, handle).accepted == first.accepted
    assert :ok = ack(context, handle, update)
    assert snapshot(context, handle).accepted == RootPort.summary(next)
    assert {:ok, noop} = LocalView.update(context.supervisor, handle, 2, %{"count" => 2})
    assert :ok = ack(context, handle, noop)
    assert snapshot(context, handle).accepted.correlation.revision == 3
  end

  test "semantic and renderer rejection preserve final state and consume distinct attempts",
       context do
    {handle, first} = mounted(context)
    Agent.update(context.settings, &Map.put(&1, :semantic, true))
    assert {:error, :semantic_rejected} = LocalView.update(context.supervisor, handle, 1, %{})
    Agent.update(context.settings, &Map.put(&1, :semantic, false))
    assert {:ok, correlation} = LocalView.update(context.supervisor, handle, 1, %{})
    assert correlation.sequence == 3
    assert {:error, :renderer_rejected} = ack(context, handle, correlation, :rolled_back)
    assert snapshot(context, handle).accepted == RootPort.summary(first)
    assert {:ok, retry} = LocalView.update(context.supervisor, handle, 1, %{})
    assert retry.transaction != correlation.transaction
    assert {:error, :stale} = ack(context, handle, correlation)
    assert :ok = ack(context, handle, retry)
  end

  test "replacement cleanup waits for commit and removal disposes exactly once", context do
    {handle, first} = mounted(context)
    assert {:ok, replacement} = LocalView.replace(context.supervisor, handle, 1, context.spec)
    assert replacement.generation == 2 and replacement.revision == 1
    refute_receive {:cleanup, _}
    assert snapshot(context, handle).accepted == RootPort.summary(first)
    assert :ok = ack(context, handle, replacement)
    assert_receive {:cleanup, :replace}
    assert {:ok, dispose} = LocalView.stop(context.supervisor, handle, :removal)
    assert {:ok, ^dispose} = LocalView.stop(context.supervisor, handle, :removal)
    assert {:error, :busy} = LocalView.update(context.supervisor, handle, 1, %{})
    assert :ok = ack(context, handle, dispose)
    assert_receive {:cleanup, :removal}
    assert :ok = LocalView.stop(context.supervisor, handle)
    refute_receive {:cleanup, _}
    assert snapshot(context, handle).status == :disposed

    assert {:error, :instance_reused} =
             LocalView.start(context.supervisor, context.spec, context.ports)

    {:ok, fresh} =
      LocalView.start(context.supervisor, %{context.spec | instance: "new"}, context.ports)

    assert fresh.instance == "new"
    assert {:error, :stale} = LocalView.inspect_root(context.supervisor, handle)
  end

  test "stop cancels an in-flight candidate and stale acknowledgements cannot revive it",
       context do
    {handle, first} = mounted(context)
    {:ok, update} = LocalView.update(context.supervisor, handle, 1, %{"count" => 4})
    {:ok, dispose} = LocalView.stop(context.supervisor, handle)
    assert_receive {:cancel, ^update}
    assert {:error, :stale} = ack(context, handle, update)
    assert :ok = ack(context, handle, dispose)
    assert snapshot(context, handle).accepted == RootPort.summary(first)
    assert {:error, :terminal} = ack(context, handle, update)
  end

  test "lost mount acknowledgement times out without false readiness", context do
    {:ok, handle} =
      LocalView.start(context.supervisor, %{context.spec | timeout_ms: 20}, context.ports)

    assert_receive {:submit, correlation, _}
    assert_receive {:cancel, ^correlation}, 1000
    assert_receive {:host, %{event: :failed, error: :timeout}}, 1000
    assert snapshot(context, handle).accepted == nil
    assert snapshot(context, handle).status == :failed
    refute_receive {:host, %{event: :ready}}
  end

  test "lost update acknowledgement confirms rollback or fails closed", context do
    {handle, first} = mounted(context, %{context.spec | timeout_ms: 100})
    {:ok, correlation} = LocalView.update(context.supervisor, handle, 1, %{})
    assert_receive {:cancel, ^correlation}, 1000
    assert_receive {:host, %{event: :rejected, error: :timeout}}, 1000
    assert snapshot(context, handle).accepted == RootPort.summary(first)
    Agent.update(context.settings, &Map.put(&1, :cancel, {:error, :private}))
    {:ok, correlation} = LocalView.update(context.supervisor, handle, 1, %{})
    assert_receive {:cancel, ^correlation}, 1000
    assert_receive {:host, %{event: :failed, error: :rollback_failed}}, 1000
    assert snapshot(context, handle).accepted == RootPort.summary(first)
    assert snapshot(context, handle).status == :failed
  end

  test "root crash before and after commit is redacted and siblings remain alive", context do
    {sibling, _} = mounted(context, %{context.spec | root: "sibling"})

    for commit <- [false, true] do
      instance = if commit, do: "after", else: "before"

      {:ok, handle} =
        LocalView.start(context.supervisor, %{context.spec | instance: instance}, context.ports)

      assert_receive {:submit, correlation, _}
      if commit, do: assert(:ok == ack(context, handle, correlation))
      # Deliberate white-box fault injection; these PIDs are never API results.
      {_, guardian, _, _} =
        Enum.find(Supervisor.which_children(context.supervisor), fn {id, _, _, _} ->
          id == {:blazex_root, "r"}
        end)

      worker = :sys.get_state(guardian).worker
      Process.exit(worker, :kill)
      assert_receive {:host, %{event: :crashed, error: :crashed, handle: ^handle}}, 1000
      assert snapshot(context, handle).status == :failed
      assert snapshot(context, handle).accepted != nil == commit
      assert snapshot(context, sibling).status == :ready
      assert Process.alive?(context.supervisor)
    end
  end

  test "invalid bootstrap and duplicate active roots do not start extra children", context do
    assert {:error, :invalid_start} =
             LocalView.start(
               context.supervisor,
               %{context.spec | props: %{bad: self()}},
               context.ports
             )

    assert Supervisor.which_children(context.supervisor) == []
    {handle, _} = mounted(context)

    assert {:error, :already_started} =
             LocalView.start(context.supervisor, context.spec, context.ports)

    assert {:error, :invalid_request} = LocalView.update(context.supervisor, handle, 1, %{bad: 1})
    assert {:error, :stale} = LocalView.update(context.supervisor, handle, 0, %{})
    assert length(Supervisor.which_children(context.supervisor)) == 1
  end

  test "submission failure requires cancellation and preserves the accepted record", context do
    {handle, first} = mounted(context)
    Agent.update(context.settings, &Map.put(&1, :submit, {:error, :private}))
    assert {:error, :renderer_rejected} = LocalView.update(context.supervisor, handle, 1, %{})
    assert_receive {:cancel, %{operation: :update}}
    assert snapshot(context, handle).accepted == RootPort.summary(first)
    assert snapshot(context, handle).status == :ready
  end

  test "cleanup failure after replacement commit retains the committed candidate but is not ready",
       context do
    {handle, _} = mounted(context)
    Agent.update(context.settings, &Map.put(&1, :cleanup, {:error, :private}))
    {:ok, replace} = LocalView.replace(context.supervisor, handle, 1, context.spec)
    assert_receive {:submit, ^replace, candidate}
    assert {:error, :cleanup_failed} = ack(context, handle, replace)
    assert snapshot(context, handle).accepted == RootPort.summary(candidate)
    assert snapshot(context, handle).status == :failed
    assert :ok = LocalView.stop(context.supervisor, handle)
    assert_receive {:cleanup, :replace}
    refute_receive {:cleanup, _}
  end

  test "disposal acknowledgement loss is terminal and cannot trigger callback replay", context do
    {handle, _} = mounted(context, %{context.spec | timeout_ms: 100})
    {:ok, dispose} = LocalView.stop(context.supervisor, handle)
    assert_receive {:cancel, ^dispose}, 1000
    assert_receive {:host, %{event: :failed, error: :timeout}}, 1000
    assert snapshot(context, handle).status == :failed
    refute_receive {:cleanup, _}
    assert :ok = LocalView.stop(context.supervisor, handle)
    refute_receive {:cleanup, _}
  end

  test "ERTS system status redacts candidate tokens and private port configuration", context do
    {handle, _} = mounted(context)
    {_, guardian, _, _} = hd(Supervisor.which_children(context.supervisor))
    worker = :sys.get_state(guardian).worker

    for pid <- [guardian, worker] do
      status = inspect(:sys.get_status(pid), limit: :infinity)
      refute status =~ "private_token"
      refute status =~ "settings:"
      assert status =~ "redacted_root"
    end

    assert snapshot(context, handle).status == :ready
  end
end
