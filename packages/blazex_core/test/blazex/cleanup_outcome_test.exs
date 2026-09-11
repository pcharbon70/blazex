defmodule BlazeX.CleanupOutcomeTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.CleanupOutcome

  defp owner, do: %{root: "r", generation: 1, path: []}
  defp lease(id), do: %{id: id, owner: owner(), acquisition: %{large: String.duplicate("x", 512)}}

  test "homogeneous pages retain exact identities without acquisition payloads" do
    page = CleanupOutcome.lease_page([lease("one"), lease("two")], [:completed, :completed], 7)
    assert page.status == :completed
    assert page.force_status == :not_requested
    assert page.unresolved == false
    assert page.identities == [{owner(), "one"}, {owner(), "two"}]
    refute inspect(page) =~ "large"
    assert CleanupOutcome.valid_page?(page)
    assert CleanupOutcome.terminal_statuses([page]) == [:released, :released]
  end

  test "mixed and forced outcomes preserve the exact failed position" do
    page = CleanupOutcome.lease_page([lease("one"), lease("two")], [:completed, :failed], 3)
    page = CleanupOutcome.apply_force(page, %{1 => :completed})
    assert page.status == [:completed, :failed]
    assert page.force_status == [:not_requested, :completed]
    assert page.unresolved == false

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
    assert CleanupOutcome.unresolved_identities([page]) == [{owner(), "one"}, {owner(), "two"}]
    assert Enum.map(CleanupOutcome.rows([page]), & &1.reference.id) == ["one", "two"]
  end

  test "malformed and oversized pages fail closed" do
    page = CleanupOutcome.lease_page([lease("one")], [:completed], 0)
    refute CleanupOutcome.valid_page?(%{page | status: []})
    refute CleanupOutcome.valid_page?(%{page | version: 2})
    refute CleanupOutcome.valid_page?(%{page | identities: List.duplicate({owner(), "x"}, 65)})
  end
end
