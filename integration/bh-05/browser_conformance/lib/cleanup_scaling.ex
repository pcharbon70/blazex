defmodule BlazeX.BH05.CleanupScaling do
  @moduledoc false
  alias BlazeX.Component.{ActionLedger, ActionRuntime, CleanupOutcome, RecoveryCleanup}

  @counts [0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512]
  @maximum_counts [64, 65, 256, 512]
  @minimal_counts [64, 512]
  @factor_profiles [
    :inventory_only,
    :payload_only,
    :identifier_only,
    :owner_depth_only,
    :distribution_only,
    :outcome_retention,
    :maximum
  ]

  defmodule Port do
    def dispose(_, _), do: :ok
    def force_cleanup(_, _), do: :ok
    def release(_, _), do: :released
    def release_page(_, leases), do: List.duplicate(:released, length(leases))

    def prepare_release(_, lease),
      do: {:ok, %{provider: lease.selection.name, token: lease.acquisition.sequence}}

    def release_prepared_ticket_page(_, tickets), do: List.duplicate(:released, length(tickets))
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

  def run_factor_matrix do
    samples =
      Enum.flat_map(@factor_profiles, fn profile ->
        Enum.map([256, 512], &observe(profile, &1, 1))
      end)

    passed = Enum.all?(samples, &(&1["acceptance_state"] == "passed"))

    %{
      "schema_version" => "1.0.0",
      "execution_state" => "executed",
      "acceptance_state" => if(passed, do: "passed", else: "failed"),
      "result" => if(passed, do: "passed", else: "failed"),
      "factor_profiles" => Enum.map(@factor_profiles, &Atom.to_string/1),
      "samples" => samples
    }
  end

  def run_factor_point(profile, count)
      when profile in @factor_profiles and count in [256, 512] do
    sample = observe(profile, count, 1)

    %{
      "schema_version" => "1.0.0",
      "execution_state" => "executed",
      "acceptance_state" => sample["acceptance_state"],
      "result" => sample["acceptance_state"],
      "factor_profiles" => [Atom.to_string(profile)],
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
      "outcome_format" =>
        report.outcome_format
        |> Map.put("retained_outcome_bytes", report.outcome_format.encoded_bytes)
        |> Map.put(
          "retained_owner_records",
          report.outcome_format.owner_records
        )
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
      "runtime_owned_inventory" => value.runtime_owned_inventory,
      "inventory_before" => value.inventory_before,
      "inventory_after" => value.inventory_after,
      "inventory_peak" => value.inventory.inventory_peak,
      "inventory_pages_sent" => value.inventory.inventory_pages_sent,
      "inventory_pages_received" => value.inventory.inventory_pages_received,
      "inventory_items_sent" => value.inventory.inventory_items_sent,
      "inventory_messages" =>
        value.inventory.inventory_messages_sent + value.inventory.inventory_messages_received,
      "inventory_request_bytes" => value.inventory.inventory_request_bytes,
      "inventory_result_bytes" => value.inventory.inventory_result_bytes,
      "ticket_preparations" => value.inventory.ticket_preparations,
      "tickets_prepared" => value.inventory.tickets_prepared,
      "ticket_preparation_failures" => value.inventory.ticket_preparation_failures,
      "ticket_preparation_pages" => value.inventory.ticket_preparation_pages,
      "ticket_bytes" => value.inventory.ticket_bytes,
      "ticket_owner_fields" => value.inventory.ticket_owner_fields,
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

      lease_owner = owner(payload_class, owner, sequence)

      {id,
       %{
         id: id,
         owner: lease_owner,
         selection: %{name: "fixture"},
         acquisition: acquisition(payload_class, sequence),
         release_requested: false
       }}
    end)
  end

  defp identifier(:minimal, sequence), do: "l#{sequence}"

  defp identifier(profile, sequence) when profile in [:maximum, :identifier_only],
    do: padded_id(sequence, 64)

  defp identifier(:inventory_only, sequence), do: "l#{sequence}"
  defp identifier(_profile, sequence), do: padded_id(sequence, 32)

  defp padded_id(sequence, bytes) do
    base = "lease-#{sequence}-"
    base <> String.duplicate("x", bytes - byte_size(base))
  end

  defp acquisition(profile, sequence)
       when profile in [:minimal, :inventory_only, :outcome_retention],
       do: %{sequence: sequence}

  defp acquisition(:canonical, sequence),
    do: %{sequence: sequence, payload: String.duplicate("c", 64)}

  defp acquisition(profile, sequence) when profile in [:maximum, :payload_only],
    do: %{sequence: sequence, payload: String.duplicate("m", 8192)}

  defp acquisition(_profile, sequence),
    do: %{sequence: sequence, payload: String.duplicate("c", 64)}

  defp owner(profile, owner, sequence) when profile in [:maximum, :outcome_retention],
    do: distributed_owner(owner, sequence, 16)

  defp owner(:owner_depth_only, owner, _sequence),
    do: %{owner | path: Enum.map(1..16, &"owner-depth-#{&1}")}

  defp owner(:distribution_only, owner, sequence),
    do: distributed_owner(owner, sequence, 1)

  defp owner(_profile, owner, _sequence), do: owner

  defp distributed_owner(owner, sequence, depth) do
    path = Enum.map(1..depth, &"owner-#{rem(sequence + &1, 128)}")
    %{owner | path: path}
  end
end
