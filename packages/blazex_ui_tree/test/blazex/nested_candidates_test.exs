defmodule BlazeX.NestedCandidatesTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.NestedTable
  alias BlazeX.UITree.{CompositionPlan, NestedCandidates}

  defmodule Shell do
    use BlazeX.Component, role: :pure, schema: [props: [], slots: []]
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule Counter do
    use BlazeX.Component,
      role: :stateful,
      schema: [
        props: [
          {"seed", [type: :integer, default: 1]},
          {"label", [type: :string, default: "count"]}
        ],
        slots: []
      ]

    def init(%{props: %{"seed" => seed}}), do: {:state, seed}
    def update(_), do: :no_change

    def render(%{state: {:present, count}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: Integer.to_string(count)}}}
  end

  defmodule Bad do
    use BlazeX.Component, role: :stateful, schema: [props: [], slots: []]
    def init(_), do: {:actions, 0, [{:effect, "clock", %{}}]}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  def graph do
    %{
      "root" => %{
        module: Shell,
        public_id: "shell",
        site: "site",
        key: "root",
        props: %{},
        slots: %{},
        children: ["counter"]
      },
      "counter" => %{
        module: Counter,
        public_id: "counter",
        site: "site",
        key: "key",
        props: %{},
        slots: %{},
        children: []
      }
    }
  end

  def plan(graph \\ graph()),
    do:
      CompositionPlan.build(
        "root",
        1,
        "root",
        graph,
        %{kind: :local, root: "root", owner: "root"},
        [],
        [:pure, :stateful]
      )
      |> NestedCandidates.preflight()

  test "mount initializes once; compatible no-op and prop updates preserve local state" do
    plan = plan()
    {candidate, records, trace, []} = NestedCandidates.evaluate(plan, %{}, 1, 0)
    assert candidate.children |> hd() |> Map.fetch!(:output) == %{kind: :text, content: "1"}
    assert Enum.map(trace, & &1.event) == [:insert, :render, :insert, :init, :render]
    assert {:ok, table} = NestedTable.new(plan.identity, 1, 0, records)
    assert NestedTable.valid?(table)
    changed = plan(put_in(graph(), ["counter", :props], %{"seed" => 99, "label" => "changed"}))
    {_, next, trace, []} = NestedCandidates.evaluate(changed, NestedTable.index(table), 2, 0)
    assert List.last(next).state == {:present, 1}
    assert Enum.map(trace, & &1.event) == [:retain, :render, :retain, :no_change, :render]
    assert {:ok, _} = NestedTable.new(plan.identity, 2, 0, next)
    assert NestedTable.valid?(table)
  end

  test "table rejects nonportable state, drifted metadata, duplicate identity and ownership" do
    plan = plan()
    {_, records, _, _} = NestedCandidates.evaluate(plan, %{}, 1, 0)

    for bad <- [
          records ++ [List.last(records)],
          List.update_at(records, 1, &%{&1 | state: {:present, self()}}),
          List.update_at(records, 1, &%{&1 | revision: 0}),
          List.update_at(records, 1, &%{&1 | parent: nil}),
          List.update_at(records, 1, &%{&1 | owned_actions: ["resource"]}),
          List.update_at(records, 1, &%{&1 | invocation_digest: String.duplicate("0", 64)})
        ] do
      assert {:error, :invalid_nested_table} = NestedTable.new(plan.identity, 1, 0, bad)
    end

    assert {:ok, table} = NestedTable.new(plan.identity, 1, 0, records)
    refute NestedTable.valid?(%{table | sequence: 1})
  end

  test "pure entry stays pure-only and prohibited init results cannot create a table" do
    assert {:composition_error, :pure_contract, [0]} =
             catch_throw(
               CompositionPlan.build(
                 "root",
                 1,
                 "root",
                 graph(),
                 %{kind: :local, root: "root", owner: "root"},
                 []
               )
             )

    bad = graph() |> put_in(["counter", :module], Bad)

    assert {:composition_error, :invalid_result, [0]} =
             catch_throw(NestedCandidates.evaluate(plan(bad), %{}, 1, 0))

    assert {:composition_error, :pure_contract, []} =
             catch_throw(plan(put_in(graph(), ["root", :module], Counter)))
  end
end
