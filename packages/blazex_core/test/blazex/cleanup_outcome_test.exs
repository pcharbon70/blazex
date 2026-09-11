defmodule BlazeX.CleanupOutcomeTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.CleanupOutcome

  defp owner, do: %{root: "r", generation: 1, path: []}
  defp lease(id), do: %{id: id, owner: owner(), acquisition: %{large: String.duplicate("x", 512)}}

  test "homogeneous pages retain ordered ids without owner or acquisition graphs" do
    page = CleanupOutcome.lease_page([lease("one"), lease("two")], [:completed, :completed], 7)
    assert page.status == :completed
    assert page.force_status == :not_requested
    assert page.unresolved == false
    assert page.identities == ["one", "two"]
    assert page.unresolved_owners == []
    refute inspect(page) =~ "large"
    refute inspect(page) =~ "generation"
    assert CleanupOutcome.valid_page?(page)
    assert CleanupOutcome.terminal_statuses([page]) == [:released, :released]
    assert CleanupOutcome.matches_leases?([page], [lease("one"), lease("two")])
    refute CleanupOutcome.matches_leases?([page], [lease("two"), lease("one")])

    assert CleanupOutcome.terminal_summary([page], [lease("one"), lease("two")]) == %{
             count: 2,
             released: 2,
             lost: 0,
             history: [
               {:released, "one", lease("one").acquisition},
               {:released, "two", lease("two").acquisition}
             ]
           }
  end

  test "mixed and forced outcomes preserve the exact failed position" do
    page = CleanupOutcome.lease_page([lease("one"), lease("two")], [:completed, :failed], 3)
    assert page.unresolved_owners == [{1, owner()}]
    page = CleanupOutcome.apply_force(page, %{1 => :completed})
    assert page.status == [:completed, :failed]
    assert page.force_status == [:not_requested, :completed]
    assert page.unresolved == false
    assert page.unresolved_owners == []

    assert CleanupOutcome.counts([page]) == %{
             requested: 2,
             failed: 1,
             timed_out: 0,
             forced: 1,
             unresolved: 0
           }
  end

  test "unresolved extraction and diagnostic expansion remain exact" do
    page = CleanupOutcome.lease_page([lease("one"), lease("two")], [:failed, :timed_out], 4)
    page = CleanupOutcome.apply_force(page, %{0 => :failed, 1 => :timed_out})
    assert page.unresolved_owners == [{0, owner()}, {1, owner()}]
    assert CleanupOutcome.unresolved_identities([page]) == [{owner(), "one"}, {owner(), "two"}]
    assert Enum.map(CleanupOutcome.rows([page]), & &1.reference.id) == ["one", "two"]
  end

  test "malformed and oversized pages fail closed" do
    page = CleanupOutcome.lease_page([lease("one")], [:completed], 0)
    refute CleanupOutcome.valid_page?(%{page | status: []})
    refute CleanupOutcome.valid_page?(%{page | version: 3})
    refute CleanupOutcome.valid_page?(%{page | identities: List.duplicate("x", 65)})

    mixed = CleanupOutcome.lease_page([lease("one"), lease("two")], [:completed, :failed], 0)
    refute CleanupOutcome.valid_page?(%{mixed | identities: tl(mixed.identities)})
    refute CleanupOutcome.valid_page?(%{mixed | unresolved_owners: [{0, owner()}]})
    refute CleanupOutcome.valid_page?(%{mixed | unresolved_owners: [{1, owner()}, {1, owner()}]})
  end

  test "successful outcome size is independent of deep owner graphs" do
    shallow = Enum.map(1..64, &%{lease(Integer.to_string(&1)) | owner: owner()})

    deep =
      Enum.map(1..64, fn index ->
        owner = %{owner() | path: Enum.map(1..16, &"#{index}-#{&1}")}
        %{lease(Integer.to_string(index)) | owner: owner}
      end)

    shallow_page = CleanupOutcome.lease_page(shallow, List.duplicate(:completed, 64), 0)
    deep_page = CleanupOutcome.lease_page(deep, List.duplicate(:completed, 64), 0)

    assert :erlang.term_to_binary(shallow_page) == :erlang.term_to_binary(deep_page)
    assert CleanupOutcome.representation([deep_page]).owner_records == 0
  end
end
