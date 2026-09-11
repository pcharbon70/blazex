defmodule BlazeX.BH05.CleanupScaling do
  @moduledoc false
  alias BlazeX.Component.{ActionLedger, ActionRuntime, CleanupOutcome, RecoveryCleanup}

  @counts [0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512]
  @maximum_counts [64, 65, 256, 512]
  @minimal_counts [64, 512]

  defmodule Port do
    def dispose(_, _), do: :ok
    def force_cleanup(_, _), do: :ok
    def release(_, _), do: :released
    def release_page(_, leases), do: List.duplicate(:released, length(leases))
  end

  def run(runtime \\ :browser) do
    samples =
      workloads(runtime)
      |> Enum.flat_map(fn {payload_class, count, repetitions} ->
        _discarded_warmup = observe(payload_class, count, 0)
        Enum.map(1..repetitions, &observe(payload_class, count, &1))
      end)

    passed = Enum.all?(samples, &(&1["acceptance_state"] == "passed"))

    %{
      "schema_version" => "1.0.0",
      "execution_state" => "executed",
      "acceptance_state" => if(passed, do: "passed", else: "failed"),
      "result" => if(passed, do: "passed", else: "failed"),
      "samples" => samples
    }
  end

  def run_probe do
    sample = observe(:canonical, 512, 1)

    %{
      "schema_version" => "1.0.0",
      "execution_state" => "executed",
      "acceptance_state" => sample["acceptance_state"],
      "result" => sample["acceptance_state"],
      "samples" => [sample]
    }
  end

  def run_subset do
    samples = Enum.map([64, 65, 256, 512], &observe(:canonical, &1, 1))
    passed = Enum.all?(samples, &(&1["acceptance_state"] == "passed"))

    %{
      "schema_version" => "1.0.0",
      "execution_state" => "executed",
      "acceptance_state" => if(passed, do: "passed", else: "failed"),
      "result" => if(passed, do: "passed", else: "failed"),
      "samples" => samples
    }
  end

  def run_point(payload_class, count)
      when payload_class in [:canonical, :maximum, :minimal] and
             count in [0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512] do
    sample = observe(payload_class, count, 1)

    %{
      "schema_version" => "1.0.0",
      "execution_state" => "executed",
      "acceptance_state" => sample["acceptance_state"],
      "result" => sample["acceptance_state"],
      "samples" => [sample]
    }
  end

  def workloads(runtime) do
    Enum.map(@counts, &{:canonical, &1})
    |> Kernel.++(Enum.map(@maximum_counts, &{:maximum, &1}))
    |> Kernel.++(Enum.map(@minimal_counts, &{:minimal, &1}))
    |> Enum.map(fn {payload, count} -> {payload, count, repetitions(runtime, count)} end)
  end

  defp repetitions(:erts, 512), do: 100
  defp repetitions(:erts, _), do: 20
  defp repetitions(_, 512), do: 20
  defp repetitions(_, _), do: 10

  defp observe(payload_class, count, sample) do
    cleaned = RecoveryCleanup.run(cleanup_state(payload_class, count, sample), :shutdown)
    report = cleaned.recovery.cleanup
    unresolved = Enum.map(CleanupOutcome.unresolved_identities(report.pages), &elem(&1, 1))

    accepted =
      report.unresolved == 0 and unresolved == [] and
        map_size(cleaned.actions.ledger.leases) == 0 and not report.exceeded_deadline

    %{
      "payload_class" => Atom.to_string(payload_class),
      "count" => count,
      "sample" => sample,
      "retained" => sample > 0,
      "execution_state" => "executed",
      "acceptance_state" => if(accepted, do: "passed", else: "failed"),
      "elapsed_ms" => report.elapsed_ms,
      "exceeded_deadline" => report.exceeded_deadline,
      "terminal_leases" => map_size(cleaned.actions.ledger.leases),
      "unresolved_identities" => unresolved,
      "lost_closed_identities" => unresolved,
      "amplification" => flatten(report.amplification),
      "runtime_metrics" => report.runtime_metrics,
      "stage_timings_ms" => report.stage_timings_ms,
      "outcome_format" => report.outcome_format
    }
  end

  defp flatten(value) do
    %{
      "page_size" => value.page_size,
      "maximum_page_size" => value.maximum_page_size,
      "normal_worker_starts" => value.normal_worker_starts,
      "forced_worker_starts" => value.forced_worker_starts,
      "total_worker_starts" => value.total_worker_starts,
      "peak_live_cleanup_workers" => value.peak_live_cleanup_workers,
      "lease_pages_sent" => value.lease_pages_sent,
      "protocol_messages" => value.protocol_messages,
      "normal_pages_sent" => value.normal.pages_sent,
      "forced_pages_sent" => value.forced.pages_sent,
      "callbacks_attempted" => value.callbacks_attempted,
      "callbacks_completed" => value.callbacks_completed,
      "request_bytes" => metric_sum(value.normal.request_bytes, value.forced.request_bytes),
      "result_bytes" => metric_sum(value.normal.result_bytes, value.forced.result_bytes)
    }
  end

  defp metric_sum(left, right) when is_integer(left) and is_integer(right), do: left + right
  defp metric_sum(_, _), do: "unavailable"

  defp cleanup_state(payload_class, count, sample) do
    root = "scale-#{payload_class}-#{count}-#{sample}"
    owner = %{root: root, generation: 1, path: []}

    actions =
      %ActionRuntime{
        ledger: ledger(payload_class, count, owner),
        port: {Port, nil}
      }
      |> ActionRuntime.seed_inventory()

    %{
      spec: %{root: root},
      accepted: nil,
      pending: nil,
      actions: actions,
      schedule: nil,
      recovery: %{generation: 1, cleanup: nil, cleaned_generation: nil},
      ports: %{renderer: {Port, nil}, evaluator: nil}
    }
  end

  defp ledger(payload_class, count, owner) do
    leases = leases(payload_class, count, owner)
    %ActionLedger{leases: leases, lease_order: leases |> Map.keys() |> Enum.sort()}
  end

  defp leases(_payload_class, 0, _owner), do: %{}

  defp leases(payload_class, count, owner) do
    Map.new(1..count, fn sequence ->
      id = identifier(payload_class, sequence)

      lease_owner =
        if payload_class == :maximum, do: distributed_owner(owner, sequence), else: owner

      {id,
       %{
         id: id,
         owner: lease_owner,
         acquisition: acquisition(payload_class, sequence),
         release_requested: false
       }}
    end)
  end

  defp identifier(:minimal, sequence), do: "l#{sequence}"
  defp identifier(:canonical, sequence), do: padded_id(sequence, 32)
  defp identifier(:maximum, sequence), do: padded_id(sequence, 64)

  defp padded_id(sequence, bytes) do
    base = "lease-#{sequence}-"
    base <> String.duplicate("x", bytes - byte_size(base))
  end

  defp acquisition(:minimal, sequence), do: %{sequence: sequence}

  defp acquisition(:canonical, sequence),
    do: %{sequence: sequence, payload: String.duplicate("c", 64)}

  defp acquisition(:maximum, sequence),
    do: %{sequence: sequence, payload: String.duplicate("m", 8192)}

  defp distributed_owner(owner, sequence) do
    path = Enum.map(1..16, &"owner-#{rem(sequence + &1, 128)}")
    %{owner | path: path}
  end
end
