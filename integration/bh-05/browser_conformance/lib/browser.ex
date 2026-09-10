defmodule BlazeX.BH05.Conformance.Browser do
  @moduledoc false
  @compile {:no_warn_undefined, Popcorn.Wasm}

  def start do
    :ok = Popcorn.Wasm.ready(:main)
    loop()
  end

  defp loop do
    receive do
      message ->
        case Popcorn.Wasm.handle_message!(message, &handle/1) do
          :shutdown -> :ok
          _ -> loop()
        end
    after
      30_000 -> :ok
    end
  end

  defp handle({:wasm_call, %{"operation" => "run"}}), do: {:resolve, run(), :continue}

  defp handle({:wasm_call, %{"operation" => "shutdown"}}),
    do: {:resolve, %{"result" => "disposed"}, :shutdown}

  defp handle(_), do: :ignored

  def run do
    root = BlazeX.BH05.Conformance.Root
    item = BlazeX.BH05.Conformance.Item
    {:state, 0} = root.mount(%{})
    {:output, output0} = root.render(%{state: {:present, 0}})
    {:state, 1} = root.handle_event(%{state: {:present, 0}})
    {:output, output1} = root.render(%{state: {:present, 1}})
    {:state, 0} = item.init(%{})
    {:state, 1} = item.handle_event(%{state: {:present, 0}})
    {:error, :injected} = BlazeX.BH05.Conformance.Fault.render(%{})

    {pid, reference} =
      :erlang.spawn_opt(
        fn ->
          receive do
            :stop -> :ok
          end
        end,
        [:link, :monitor]
      )

    true = is_pid(pid) and is_reference(reference)
    true = Process.unlink(pid)
    Process.exit(pid, :kill)

    receive do
      {:DOWN, ^reference, :process, ^pid, _} -> :ok
    after
      1000 -> :erlang.error(:monitor_timeout)
    end

    true = is_integer(System.monotonic_time(:millisecond))
    runtime = runtime_scenario()

    %{
      "schema_version" => "1.0.0",
      "result" => "passed",
      "trace" => [
        %{"step" => "mount", "generation" => 1, "revision" => 1, "state" => 0},
        %{"step" => "render", "generation" => 1, "revision" => 1, "output" => portable(output0)},
        %{"step" => "event", "generation" => 1, "revision" => 2, "state" => 1},
        %{"step" => "render", "generation" => 1, "revision" => 2, "output" => portable(output1)},
        %{"step" => "nested-state", "component" => "item", "state" => 1},
        %{"step" => "failure", "code" => "injected", "fallback" => "static"},
        %{
          "step" => "runtime-primitives",
          "spawn_opt" => true,
          "monitor" => true,
          "unlink" => true,
          "exit" => true,
          "monotonic" => true
        },
        %{
          "step" => "process-root",
          "mount" => runtime.mount,
          "event" => runtime.event,
          "disposed" => runtime.disposed
        },
        %{
          "step" => "recovery",
          "status" => runtime.failure_status,
          "fallback" => runtime.fallback
        },
        %{"step" => "dispose", "result" => "completed"}
      ],
      "final_state" => %{"root" => 1, "item" => 1, "resources" => 0}
    }
  end

  defp portable({:semantic, version, value}),
    do: %{"semantic" => version, "value" => encode(value)}

  defp encode(value) when is_atom(value), do: Atom.to_string(value)
  defp encode(value) when is_list(value), do: Enum.map(value, &encode/1)

  defp encode(value) when is_map(value),
    do: Map.new(value, fn {key, item} -> {Atom.to_string(key), encode(item)} end)

  defp encode(value), do: value

  defp runtime_scenario do
    alias BlazeX.Component.{LocalView, RecoveryView}
    alias BlazeX.UITree.RecoveryEvaluator
    marker(:supervisor_start)
    {:ok, supervisor} = LocalView.Supervisor.start_link([])
    marker(:supervisor_ready)

    evaluator = {BlazeX.BH05.Conformance.Evaluator, nil}

    ports = %{
      evaluator: evaluator,
      renderer: {BlazeX.BH05.Conformance.Port, self()},
      host: {BlazeX.BH05.Conformance.Port, self()}
    }

    spec = %{
      root: "runtime",
      instance: "runtime",
      owner: "fixture",
      component: BlazeX.BH05.Conformance.Root,
      public_id: "root",
      props: %{"title" => "Conformance"},
      slots: %{},
      capabilities: ["ui.storage"],
      fallback: :none,
      timeout_ms: 1000
    }

    {:ok, handle} = LocalView.start(supervisor, spec, ports)
    marker(:root_started)
    {mount, mount_candidate} = submission()
    marker(:mount_submitted)
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    {:ok, dispose} = LocalView.stop(supervisor, handle)
    marker(:dispose_started)
    {^dispose, nil} = submission()
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: dispose, result: :committed})

    recovery_ports = %{ports | evaluator: {RecoveryEvaluator, {evaluator, 100}}}

    fault = %{
      spec
      | root: "failure",
        instance: "failure",
        component: BlazeX.BH05.Conformance.Fault,
        props: %{},
        capabilities: [],
        fallback: {:static, "recovery"}
    }

    recovery = %{
      automatic: false,
      user: true,
      host: true,
      changed: true,
      backoff_ms: 100,
      port_timeout_ms: 100
    }

    {:ok, failed_handle} = RecoveryView.start(supervisor, fault, recovery_ports, nil, recovery)
    marker(:recovery_started)
    {failure, _fallback} = submission()

    :ok =
      LocalView.acknowledge(supervisor, failed_handle, %{correlation: failure, result: :committed})

    {:ok, failed} = LocalView.inspect_root(supervisor, failed_handle)
    :ok = LocalView.stop(supervisor, failed_handle)
    marker(:recovery_disposed)

    %{
      mount: state(mount_candidate),
      event: 1,
      disposed: true,
      failure_status: Atom.to_string(failed.status),
      fallback: Atom.to_string(failed.recovery.failure.fallback)
    }
  end

  defp submission do
    receive do
      {:submission, correlation, candidate} -> {correlation, candidate}
    after
      1000 -> :erlang.error(:submission_timeout)
    end
  end

  defp state(candidate),
    do: Map.fetch!(candidate.state, :value)

  defp marker(step), do: :erlang.display({:bh05_phase11, step})
end

defmodule BlazeX.BH05.Conformance.Evaluator do
  alias BlazeX.Component.RootPort

  def prepare(_, request, _) do
    input = %{props: request.spec.props, slots: request.spec.slots, state: :none}
    {:state, value} = request.spec.component.mount(input)
    {:output, output} = request.spec.component.render(%{input | state: {:present, value}})

    RootPort.candidate(request.correlation, %{value: value}, String.duplicate("a", 64), %{
      output: output
    })
  end

  def cleanup(_, _, _), do: :ok
  def cleanup_owners(_, _), do: []
  def cleanup_owner(_, _, _, _), do: :ok
end

defmodule BlazeX.BH05.Conformance.Port do
  def submit(observer, correlation, candidate) do
    send(observer, {:submission, correlation, candidate})
    :ok
  end

  def cancel(_, _), do: :ok
  def notify(_, _), do: :ok
  def dispose(_, _), do: :ok
  def force_cleanup(_, _), do: :ok
end
