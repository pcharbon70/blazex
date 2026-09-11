defmodule BlazeX.ReleaseTicketTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{ActionLedger, ActionRuntime, RecoveryPort, ReleaseTicket, RootPort}

  defmodule Port do
    def prepare_release(_, lease),
      do: {:ok, %{provider: lease.selection.name, token: %{handle: lease.id}}}

    def release_ticket(observer, ticket) do
      send(observer, {:ticket, ticket})
      :released
    end
  end

  defmodule WrongPort do
    def prepare_release(_, lease),
      do: {:ok, %{provider: "other", token: %{handle: lease.id}}}
  end

  defmodule MalformedPort do
    def prepare_release(_, lease),
      do: {:ok, %{provider: lease.selection.name, token: %{handle: lease.id}}}

    def release_ticket_page(_, _), do: [:released, :released]
  end

  defp lease,
    do: %{
      id: "lease",
      owner: %{root: "root", path: ["deep"], generation: 7},
      generation: 7,
      capability: "ui.storage",
      selection: %{name: "primary"},
      acquisition: %{sequence: 1}
    }

  test "root port prepares and releases a bounded owner-free ticket" do
    assert {:ok, ticket} = RootPort.prepare_release({Port, self()}, lease())
    assert ReleaseTicket.valid?(ticket)
    assert ticket == %{version: 1, provider: "primary", id: "lease", token: %{handle: "lease"}}
    assert byte_size(:erlang.term_to_binary(ticket)) <= ReleaseTicket.maximum_bytes()

    assert [:released] = RootPort.release_ticket_page({Port, self()}, [ticket])
    assert_receive {:ticket, ^ticket}
  end

  test "root port rejects mismatched provider routing and unsafe tickets" do
    assert {:error, :invalid_release_ticket} = RootPort.prepare_release({WrongPort, nil}, lease())
    assert {:error, :invalid_release_ticket} = ReleaseTicket.new("primary", "lease", %{path: []})
    refute ReleaseTicket.valid?(%{version: 1, provider: "primary", id: "lease", token: self()})
  end

  test "failed preparation cannot manufacture owned inventory" do
    bad = %{lease() | selection: %{name: "primary"}}

    runtime =
      %ActionRuntime{
        ledger: %ActionLedger{leases: %{bad.id => bad}, lease_order: [bad.id]},
        port: {WrongPort, nil}
      }
      |> ActionRuntime.seed_inventory()

    stats = RecoveryPort.inventory_stats(runtime.cleanup_session)
    assert stats.inventory_count == 0
    assert stats.ticket_preparations == 1
    assert stats.tickets_prepared == 0
    assert stats.ticket_preparation_failures == 1
    assert Map.has_key?(runtime.ledger.leases, bad.id)
  end

  test "malformed page results cannot manufacture convergence" do
    {:ok, ticket} = RootPort.prepare_release({MalformedPort, nil}, lease())

    assert [{:error, :port_failed}] =
             RootPort.release_ticket_page({MalformedPort, nil}, [ticket])
  end

  test "ticket pages retain frozen count and size bounds" do
    tickets =
      Enum.map(1..64, fn n ->
        {:ok, ticket} = ReleaseTicket.new("primary", "lease-#{n}", %{handle: n})
        ticket
      end)

    assert ReleaseTicket.page?(tickets, 64)
    refute ReleaseTicket.page?(tickets ++ [hd(tickets)], 64)
    assert ReleaseTicket.maximum_bytes() == 4096
  end
end
