defmodule BlazeX.RecoveryCleanupTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{ActionLedger, ActionRuntime, Input, RecoveryCleanup}

  defmodule Port do
    def dispose(%{mode: :slow}, _), do: Process.sleep(200)
    def dispose(%{mode: :failed}, _), do: {:error, :unavailable}
    def dispose(_, _), do: :ok
    def force_cleanup(%{mode: :failed}, _), do: {:error, :unavailable}

    def force_cleanup(%{observer: observer}, %{reference: %{id: id}}) do
      send(observer, {:forced, id})
      :ok
    end

    def force_cleanup(_, _), do: :ok

    def release(%{fail_id: id, observer: observer}, %{id: id}) do
      send(observer, {:release_failed, id})
      {:error, :unavailable}
    end

    def release(config, lease) do
      send(config.observer, {:released, lease.id})
      :released
    end

    def prepare_release(_, lease),
      do: {:ok, %{provider: "test", token: %{handle: lease.id}}}

    def release_ticket(%{fail_id: id, observer: observer}, %{id: id}) do
      send(observer, {:release_failed, id})
      {:error, :unavailable}
    end

    def release_ticket(config, %{id: id}) do
      send(config.observer, {:released, id})
      :released
    end

    def release_ticket_page(config, tickets), do: Enum.map(tickets, &release_ticket(config, &1))

    def release_prepared_ticket_page(%{fail_id: fail_id} = config, tickets) do
      Enum.map(tickets, fn {id, _provider, _token} ->
        if id == fail_id, do: release_ticket(config, %{id: id}), else: :released
      end)
    end

    def release_prepared_ticket_page(config, tickets) do
      Enum.each(tickets, fn {id, _provider, _token} -> send(config.observer, {:released, id}) end)
      :released
    end

    def cancel(config, packet) do
      send(config.observer, {:canceled, packet.correlation})
      :ok
    end
  end

  def owner, do: %{root: "r", generation: 1, path: []}

  def state(mode \\ :ok),
    do: %{
      spec: %{root: "r"},
      accepted: nil,
      pending: nil,
      actions: nil,
      schedule: nil,
      recovery: %{generation: 1, cleanup: nil, cleaned_generation: nil},
      ports: %{renderer: {Port, %{mode: mode, observer: self()}}, evaluator: nil}
    }

  test "timeout gets forced adapter cleanup and unconfirmed release remains a blocking leak" do
    slow = RecoveryCleanup.run(state(:slow), :shutdown).recovery.cleanup
    assert slow.timed_out == 1 and slow.forced == 1 and slow.unresolved == 0
    assert slow.elapsed_ms >= 100 and slow.elapsed_ms < 1000
    failed = RecoveryCleanup.run(state(:failed), :shutdown).recovery.cleanup
    assert failed.status == :failed and failed.unresolved == 1
    assert failed.failed == 1 and failed.forced == 0
    failed_state = RecoveryCleanup.run(state(:failed), :failure)
    later = RecoveryCleanup.run(%{failed_state | ports: state().ports}, :shutdown)
    assert later.recovery.cleanup.status == :failed
    assert later.recovery.cleanup.unresolved == 1
    assert later.recovery.cleanup.unresolved_pages == failed_state.recovery.cleanup.pages
  end

  test "all 512 leases release within one deadline and inventory stays portable" do
    leases =
      Map.new(1..512, fn n ->
        id = "lease-#{n}"

        {id,
         %{
           id: id,
           owner: owner(),
           selection: %{name: "test"},
           acquisition: %{sequence: n},
           release_requested: false
         }}
      end)

    runtime =
      %ActionRuntime{
        ledger: %ActionLedger{leases: leases},
        port: {Port, %{observer: self()}}
      }
      |> ActionRuntime.seed_inventory()

    cleaned = RecoveryCleanup.run(%{state() | actions: runtime}, :replace)
    assert cleaned.recovery.cleanup.unresolved == 0
    assert cleaned.recovery.cleanup.requested == 513
    assert cleaned.recovery.cleanup.elapsed_ms < 1000
    assert cleaned.recovery.cleanup.amplification.normal_worker_starts == 0
    assert cleaned.recovery.cleanup.amplification.forced_worker_starts == 0
    assert cleaned.recovery.cleanup.amplification.total_worker_starts == 0
    assert cleaned.recovery.cleanup.amplification.peak_live_cleanup_workers == 1
    assert cleaned.recovery.cleanup.amplification.runtime_owned_inventory
    assert cleaned.recovery.cleanup.amplification.inventory_before == 512
    assert cleaned.recovery.cleanup.amplification.inventory_after == 0
    assert cleaned.recovery.cleanup.amplification.inventory.inventory_items_sent == 512
    assert cleaned.recovery.cleanup.amplification.inventory.inventory_pages_sent == 4
    assert cleaned.recovery.cleanup.amplification.inventory.ticket_preparations == 512
    assert cleaned.recovery.cleanup.amplification.inventory.tickets_prepared == 512
    assert cleaned.recovery.cleanup.amplification.inventory.ticket_preparation_failures == 0
    assert cleaned.recovery.cleanup.amplification.inventory.ticket_preparation_pages == 4
    assert cleaned.recovery.cleanup.amplification.inventory.ticket_bytes > 0
    assert cleaned.recovery.cleanup.amplification.inventory.ticket_owner_fields == 0
    assert cleaned.recovery.cleanup.amplification.lease_pages_sent == 8
    assert cleaned.recovery.cleanup.amplification.normal.pages_sent == 9
    assert cleaned.recovery.cleanup.amplification.normal.pages_received == 9
    assert cleaned.recovery.cleanup.amplification.normal.jobs_sent == 513
    assert cleaned.recovery.cleanup.amplification.normal.results_received == 513
    assert cleaned.recovery.cleanup.amplification.normal.compact_ack_pages == 8
    assert cleaned.recovery.cleanup.amplification.normal.compact_ack_items == 512
    assert cleaned.recovery.cleanup.amplification.normal.positional_result_items == 0
    assert cleaned.recovery.cleanup.amplification.normal.request_bytes > 0
    assert cleaned.recovery.cleanup.amplification.normal.result_bytes > 0
    assert cleaned.recovery.cleanup.amplification.protocol_messages == 18
    assert cleaned.recovery.cleanup.outcome_format.outcome_pages == 8
    assert cleaned.recovery.cleanup.outcome_format.identities == 512
    assert cleaned.recovery.cleanup.outcome_format.expanded_rows == 0
    assert cleaned.recovery.cleanup.outcome_format.vectors == 0

    assert cleaned.recovery.cleanup.stage_timings_ms.total ==
             cleaned.recovery.cleanup.elapsed_ms

    assert cleaned.recovery.cleanup.stage_timings_ms.lease_release >= 0
    assert cleaned.recovery.cleanup.stage_timings_ms.ledger_finalization >= 0
    assert is_map(cleaned.recovery.cleanup.runtime_metrics.process_count)
    assert Map.has_key?(cleaned.recovery.cleanup.runtime_metrics.process_count, :delta)
    assert cleaned.actions.ledger.leases == %{}
    assert Input.portable?(cleaned.recovery.cleanup)
    for _ <- 1..512, do: assert_receive({:released, _})
    again = RecoveryCleanup.run(cleaned, :shutdown)
    assert again.recovery.cleanup.requested == 1
    refute_receive {:released, _}, 10
  end

  test "pending effect and command work is canceled without resubmission" do
    entry = %{action: %{owner: owner()}, correlation: %{sequence: 1}}
    ledger = %ActionLedger{pending: %{entry.correlation => entry}}
    runtime = %ActionRuntime{ledger: ledger, port: {Port, %{observer: self()}}}
    cleaned = RecoveryCleanup.run(%{state() | actions: runtime}, :failure)
    assert cleaned.actions.ledger.pending == %{}
    assert_receive {:canceled, %{sequence: 1}}
    assert cleaned.recovery.cleanup.unresolved == 0
  end

  test "a failed resource keeps its own result and only that identity is force cleaned" do
    leases =
      Map.new(1..65, fn n ->
        id = "lease-#{n}"

        {id,
         %{
           id: id,
           owner: owner(),
           selection: %{name: "test"},
           acquisition: %{sequence: n},
           release_requested: false
         }}
      end)

    runtime =
      %ActionRuntime{
        ledger: %ActionLedger{leases: leases},
        port: {Port, %{observer: self(), fail_id: "lease-64"}}
      }
      |> ActionRuntime.seed_inventory()

    cleaned = RecoveryCleanup.run(%{state() | actions: runtime}, :replace)
    report = cleaned.recovery.cleanup
    assert report.status == :completed
    assert report.failed == 1
    assert report.forced == 1
    assert report.unresolved == 0
    assert report.amplification.lease_pages_sent == 2
    assert report.amplification.normal_worker_starts == 0
    assert report.amplification.forced_worker_starts == 1
    assert report.amplification.total_worker_starts == 1
    assert report.amplification.peak_live_cleanup_workers == 1
    assert_receive {:release_failed, "lease-64"}
    assert_receive {:forced, "lease-64"}
    refute_receive {:forced, _}, 10
    assert cleaned.actions.ledger.leases == %{}
  end

  test "a missing owned inventory fails closed into exact forced recovery" do
    lease = %{
      id: "lease-missing-owner",
      owner: owner(),
      selection: %{name: "test"},
      acquisition: %{sequence: 1, payload: String.duplicate("x", 8192)},
      release_requested: false
    }

    runtime = %ActionRuntime{
      ledger: %ActionLedger{leases: %{lease.id => lease}},
      port: {Port, %{observer: self()}}
    }

    cleaned = RecoveryCleanup.run(%{state() | actions: runtime}, :replace)
    report = cleaned.recovery.cleanup
    assert report.status == :completed and report.unresolved == 0
    refute report.amplification.runtime_owned_inventory
    assert report.amplification.normal_worker_starts == 1
    assert report.amplification.lease_pages_sent == 0
    assert report.amplification.forced_worker_starts == 1
    assert_receive {:forced, "lease-missing-owner"}
    refute_receive {:released, "lease-missing-owner"}, 10
  end

  test "page boundaries stay structural across payload and owner distributions" do
    canonical = cleanup_with(129, fn n -> owner_for(n, :single) end, fn n -> %{sequence: n} end)

    maximum =
      cleanup_with(
        129,
        fn n -> owner_for(n, :distributed) end,
        fn n -> %{sequence: n, payload: String.duplicate("x", 1024)} end
      )

    for cleaned <- [canonical, maximum] do
      report = cleaned.recovery.cleanup
      assert report.status == :completed
      assert report.unresolved == 0
      assert report.amplification.lease_pages_sent == 3
      assert report.amplification.normal_worker_starts == 0
      assert report.amplification.total_worker_starts == 0
      assert report.amplification.peak_live_cleanup_workers == 1
      assert report.amplification.protocol_messages == 8
    end

    assert maximum.recovery.cleanup.amplification.normal.request_bytes ==
             canonical.recovery.cleanup.amplification.normal.request_bytes

    assert maximum.recovery.cleanup.amplification.normal.request_bytes <
             maximum.recovery.cleanup.amplification.inventory.inventory_request_bytes
  end

  defp cleanup_with(count, owner_fun, acquisition_fun) do
    leases =
      Map.new(1..count, fn n ->
        id = "lease-" <> String.pad_leading(Integer.to_string(n), 4, "0")

        {id,
         %{
           id: id,
           owner: owner_fun.(n),
           selection: %{name: "test"},
           acquisition: acquisition_fun.(n),
           release_requested: false
         }}
      end)

    runtime =
      %ActionRuntime{
        ledger: %ActionLedger{leases: leases},
        port: {Port, %{observer: self()}}
      }
      |> ActionRuntime.seed_inventory()

    cleaned = RecoveryCleanup.run(%{state() | actions: runtime}, :replace)
    for _ <- 1..count, do: assert_receive({:released, _})
    cleaned
  end

  defp owner_for(_n, :single), do: owner()

  defp owner_for(n, :distributed),
    do: %{owner() | path: ["component-#{rem(n, 128)}"]}
end
