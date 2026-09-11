defmodule BlazeX.ReleaseTicketTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{ReleaseTicket, RootPort}

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
end
