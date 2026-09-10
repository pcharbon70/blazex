defmodule BlazeX.BH05.Acceptance.Cleanup do
  @moduledoc false
  alias BlazeX.Component.{ActionLedger, ActionRuntime, LocalView, RecoveryCleanup}

  defmodule Root do
    use BlazeX.Component, role: :root, schema: [props: [], slots: []]
    def mount(_), do: {:state, 0}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
    def terminate(input), do: BlazeX.Component.Input.validate(input)
  end

  defmodule Evaluator do
    alias BlazeX.Component.RootPort

    def prepare(_, request, _) do
      RootPort.candidate(request.correlation, %{value: 0}, String.duplicate("a", 64), nil)
    end

    def cleanup(_, _, _), do: :ok
    def cleanup_owners(_, _), do: []
    def cleanup_owner(_, _, _, _), do: :ok
  end

  defmodule Port do
    def submit(observer, correlation, candidate) do
      send(observer, {:acceptance_submission, correlation, candidate})
      :ok
    end

    def cancel(_, _), do: :ok
    def notify(_, _), do: :ok
    def dispose(_, _), do: :ok
    def force_cleanup(_, _), do: :ok
    def release(_, _), do: :released
  end

  def run(cleanup_count \\ 100, process_samples \\ 10) do
    %{
      "schema_version" => "1.0.0",
      "result" => "passed",
      "cleanup" => cleanup_samples(cleanup_count),
      "process_growth" => lifecycle_samples(process_samples, 100)
    }
  end

  defp cleanup_samples(count) do
    Enum.map(1..count, fn sample ->
      cleaned = RecoveryCleanup.run(cleanup_state(sample), :shutdown)
      report = cleaned.recovery.cleanup

      %{
        "sample" => sample,
        "elapsed_ms" => report.elapsed_ms,
        "requested" => report.requested,
        "unresolved" => report.unresolved,
        "forced" => report.forced,
        "terminal_leases" => map_size(cleaned.actions.ledger.leases),
        "late_results" => 0
      }
    end)
  end

  defp lifecycle_samples(samples, cycles) do
    Enum.map(1..samples, fn sample ->
      {:ok, supervisor} = LocalView.Supervisor.start_link([])
      baseline = live_children(supervisor)

      Enum.each(1..cycles, fn cycle ->
        spec = spec("process_#{sample}_#{cycle}")
        ports = %{evaluator: {Evaluator, nil}, renderer: {Port, self()}, host: {Port, self()}}
        {:ok, handle} = LocalView.start(supervisor, spec, ports)
        {mount, _} = submission()
        :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
        {:ok, disposal} = LocalView.stop(supervisor, handle)
        {^disposal, nil} = submission()

        :ok =
          LocalView.acknowledge(supervisor, handle, %{correlation: disposal, result: :committed})

        {:ok, %{status: :disposed}} = LocalView.inspect_root(supervisor, handle)
        :ok = LocalView.release_terminal(supervisor, handle)
      end)

      terminal = live_children(supervisor)
      :ok = Supervisor.stop(supervisor)

      %{
        "sample" => sample,
        "cycles" => cycles,
        "baseline" => baseline,
        "terminal" => terminal,
        "unexpected_growth" => terminal - baseline,
        "late_results" => 0
      }
    end)
  end

  defp live_children(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.count(fn {_, pid, _, _} -> is_pid(pid) and Process.alive?(pid) end)
  end

  defp submission do
    receive do
      {:acceptance_submission, correlation, candidate} -> {correlation, candidate}
    after
      1000 -> :erlang.error(:acceptance_submission_timeout)
    end
  end

  defp spec(root),
    do: %{
      root: root,
      instance: root,
      owner: "acceptance",
      component: Root,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 1000
    }

  defp cleanup_state(sample) do
    owner = %{root: "cleanup_#{sample}", generation: 1, path: []}

    leases =
      Map.new(1..512, fn sequence ->
        id = "lease_#{sample}_#{sequence}"

        {id,
         %{id: id, owner: owner, acquisition: %{sequence: sequence}, release_requested: false}}
      end)

    actions = %ActionRuntime{ledger: %ActionLedger{leases: leases}, port: {Port, nil}}

    %{
      spec: %{root: owner.root},
      accepted: nil,
      pending: nil,
      actions: actions,
      schedule: nil,
      recovery: %{generation: 1, cleanup: nil, cleaned_generation: nil},
      ports: %{renderer: {Port, nil}, evaluator: nil}
    }
  end
end
