defmodule BlazeX.CompositionPlanTest do
  use ExUnit.Case, async: true
  alias BlazeX.UITree.{CompositionPlan, PureCandidates}
  @boundary %{kind: :local, root: "root", owner: "root"}

  defmodule Group do
    use BlazeX.Component, role: :pure, schema: [props: [], slots: []]
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule Text do
    use BlazeX.Component,
      role: :pure,
      schema: [props: [{"text", [type: :string, required: true]}], slots: []]

    def render(%{props: %{"text" => text}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: text}}}
  end

  defmodule Fails do
    use BlazeX.Component, role: :pure, schema: [props: [], slots: []]
    def render(_), do: :erlang.error(:private_exception)
  end

  defmodule Slots do
    use BlazeX.Component,
      role: :pure,
      schema: [
        props: [{"text", [type: :string, required: true]}],
        slots: [{"default", [required: true]}, {"footer", [key: :optional]}]
      ]

    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  test "local slots retain caller props, named order and ordinal identity" do
    content = %{"owner" => "root", "caller" => "slots", "id" => "text"}
    root = spec(Slots, "slots", [], %{"text" => "lexical"})

    root = %{
      root
      | slots: %{
          "footer" => [%{"content" => content}],
          "default" => [%{"key" => "one", "content" => content}]
        }
    }

    graph = %{"root" => root, "text" => spec(Text, "text", [], %{"text" => {:caller, "text"}})}
    plan = CompositionPlan.build("root", 1, "root", graph, @boundary, [])
    assert Enum.map(plan.children, & &1.slot) == ["default", "footer"]

    assert Enum.map(plan.children, & &1.input.props) == [
             %{"text" => "lexical"},
             %{"text" => "lexical"}
           ]

    assert List.last(List.last(plan.children).identity.path) ==
             {"text", "site", "footer", {:ordinal, 0}}

    {candidate, trace} = PureCandidates.evaluate(plan)
    assert length(candidate.children) == 2
    assert Enum.count(trace, &(&1.event == :slot_expansion)) == 2

    bad =
      put_in(graph, ["root", :slots, "default"], [
        %{"key" => "one", "content" => %{content | "caller" => "wrong"}}
      ])

    assert {:composition_error, :lexical_owner, _} =
             catch_throw(CompositionPlan.build("root", 1, "root", bad, @boundary, []))
  end

  defp spec(module, id, children \\ [], props \\ %{}),
    do: %{
      module: module,
      public_id: id,
      site: "site",
      key: id,
      props: props,
      slots: %{},
      children: children
    }

  defp graph,
    do: %{
      "root" => spec(Group, "group", ["text"]),
      "text" => spec(Text, "text", [], %{"text" => "Hello"})
    }

  test "whole graph normalizes with derived identities and deterministic evaluation" do
    plan = CompositionPlan.build("root", 1, "root", graph(), @boundary, [])
    assert hd(plan.children).identity.path == [{"text", "site", :child, "text"}]
    assert {candidate, trace} = PureCandidates.evaluate(plan)
    assert hd(candidate.children).output.content == "Hello"

    assert Enum.map(trace, & &1.event) == [
             :invocation_enter,
             :invocation_enter,
             :invocation_exit,
             :invocation_exit
           ]

    assert PureCandidates.evaluate(plan) == {candidate, trace}
    reversed = graph() |> Enum.reverse() |> Map.new()
    assert CompositionPlan.build("root", 1, "root", reversed, @boundary, []) == plan
  end

  test "invalid descendant props reject before failing parent callback is reached" do
    graph = graph() |> put_in(["root", :module], Fails) |> put_in(["text", :props], %{})

    assert {:composition_error, :invocation, [0]} =
             catch_throw(CompositionPlan.build("root", 1, "root", graph, @boundary, []))
  end

  test "cycles duplicate identity unreachable and depth limits reject" do
    for {graph, code} <- [
          {put_in(graph(), ["text", :children], ["root"]), :cycle},
          {put_in(graph(), ["root", :children], ["text", "text"]), :duplicate_identity},
          {Map.put(graph(), "unused", spec(Group, "unused")), :unreachable_record}
        ] do
      assert {:composition_error, ^code, _} =
               catch_throw(CompositionPlan.build("root", 1, "root", graph, @boundary, []))
    end

    deep =
      Map.new(0..13, fn n ->
        {"n#{n}", spec(Group, "n#{n}", if(n == 13, do: [], else: ["n#{n + 1}"]))}
      end)

    assert {:composition_error, :limit, _} =
             catch_throw(CompositionPlan.build("root", 1, "n0", deep, @boundary, []))
  end
end
