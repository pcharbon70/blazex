defmodule BlazeX.CompositionTest do
  use ExUnit.Case, async: true
  alias BlazeX.UITree.{Composition, IntentSet}
  @boundary %{kind: :local, root: "root", owner: "root"}

  defmodule Output do
    use BlazeX.Component,
      role: :pure,
      capabilities: ["input"],
      schema: [props: [{"case", [type: :integer, default: 0]}], slots: []]

    def render(%{props: %{"case" => choice}}) do
      case choice do
        0 ->
          {:output,
           {:semantic, 1,
            %{
              kind: :surface,
              layout: %{mode: :stack},
              focus: %{behavior: :scope, restore: :previous}
            }}}

        1 ->
          {:output,
           {:semantic, 1,
            %{
              kind: :field,
              bindings: [:change],
              required_capabilities: ["input"],
              accessibility: %{
                role: :text_field,
                name: "Field",
                relationships: %{labelled_by: [[{"label", "site", :child, "label"}]]}
              },
              focus: %{behavior: :target, order: 0, auto_focus: true},
              selection: %{kind: :text_range, value: %{anchor: 0, focus: 1, direction: :forward}}
            }}}

        2 ->
          {:output, {:semantic, 1, %{kind: :text, content: "Label"}}}

        3 ->
          {:output, {:semantic, 1, %{kind: :group, children: []}}}

        4 ->
          {:output, {:semantic, 1, %{kind: :group, resource: "private"}}}

        5 ->
          {:state, %{private: "secret"}}

        6 ->
          {:actions, :absent, [{:effect, "private", %{}}]}

        7 ->
          {:rejected, :failed}

        8 ->
          :erlang.error(:private_exception)

        9 ->
          :erlang.raise(:throw, :private_throw, [])

        10 ->
          :erlang.raise(:exit, :private_exit, [])

        11 ->
          {:output,
           {:semantic, 1, %{kind: :text, content: "bad", focus: %{behavior: :target, order: 0}}}}

        12 ->
          {:output, {:semantic, 1, %{kind: :action, selection: %{kind: :single, value: "x"}}}}

        13 ->
          {:output, {:semantic, 1, %{kind: :group, required_capabilities: ["other"]}}}

        14 ->
          {:output, {:semantic, 1, %{kind: :group, bindings: [:change, :change]}}}

        15 ->
          {:output, {:semantic, 1, %{kind: :group, layout: %{mode: :stack, gap: {:units, -1}}}}}

        16 ->
          {:output, {:semantic, 1, %{kind: :group, effects: []}}}
      end
    end
  end

  defp spec(id, choice, children \\ []),
    do: %{
      module: Output,
      public_id: id,
      site: "site",
      key: id,
      props: %{"case" => choice},
      slots: %{},
      children: children
    }

  defp run(graph), do: Composition.evaluate("root", 1, "root", graph, @boundary, ["input"])

  defp valid,
    do: %{
      "root" => spec("root", 0, ["field", "label"]),
      "field" => spec("field", 1),
      "label" => spec("label", 2)
    }

  test "one complete intent set has root-owned bindings and resolved references" do
    assert {:ok, result} = run(valid())
    assert :ok = IntentSet.validate(result.output)
    assert result.output.document.root.kind == :surface
    assert hd(result.output.document.bindings).owner == result.output.document.root.identity
    assert length(result.output.focus) == 2
    assert List.last(result.trace) == %{event: :final_output, digest: result.output_digest}
    assert Enum.count(result.trace, &(&1.event == :semantic_node_accepted)) == 3
    for _ <- 1..10, do: assert(run(valid()) == {:ok, result})
    assert run(Map.new(Enum.reverse(Enum.to_list(valid())))) == {:ok, result}
    refute inspect(result.trace) =~ "BlazeX"
    refute inspect(result.trace) =~ "Label"
  end

  test "wrong relationship, focus and selection targets reject the entire output" do
    missing = valid() |> Map.delete("label") |> put_in(["root", :children], ["field"])
    assert {:error, %{code: :relationship_target}} = run(missing)

    for choice <- [11, 12] do
      assert {:error, %{code: :intent_set} = diagnostic} = run(%{"root" => spec("root", choice)})
      refute Map.has_key?(diagnostic, :output)
    end
  end

  test "closed candidates and constructors reject emissions, resources and invalid intent" do
    for choice <- [3, 4, 5, 6, 13, 14, 15, 16] do
      assert {:error, diagnostic} = run(%{"root" => spec("root", choice)})

      assert Map.keys(diagnostic) |> Enum.sort() == [
               :code,
               :contract,
               :path,
               :trace,
               :trace_digest
             ]

      refute inspect(diagnostic) =~ "private"
      assert run(%{"root" => spec("root", choice)}) == {:error, diagnostic}
    end
  end

  test "failing descendant discards all candidates and private exception details" do
    for {choice, code} <- [
          {7, :callback_rejected},
          {8, :callback_failed},
          {9, :callback_failed},
          {10, :callback_failed}
        ] do
      graph = %{"root" => spec("root", 0, ["child"]), "child" => spec("child", choice)}
      assert {:error, %{code: ^code, path: [0]} = diagnostic} = run(graph)
      assert diagnostic.trace == [%{event: code, code: code, path: [0]}]
      refute inspect(diagnostic) =~ "private"
      refute Map.has_key?(diagnostic, :output_digest)
    end
  end

  test "malformed graph, generation, boundary and unavailable capability reject without output" do
    for graph <- [
          nil,
          [],
          %{private: self()},
          %{"root" => %{}},
          %{"root" => %{spec("root", 0) | module: nil}}
        ] do
      assert {:error, diagnostic} = run(graph)
      refute inspect(diagnostic) =~ "private"
    end

    assert {:error, %{code: :generation}} =
             Composition.evaluate("root", 0, "root", valid(), @boundary, ["input"])

    assert {:error, %{code: :boundary}} =
             Composition.evaluate("other", 1, "root", valid(), @boundary, ["input"])

    assert {:error, %{code: :capability_unavailable}} =
             Composition.evaluate("root", 1, "root", valid(), @boundary, [])
  end
end
