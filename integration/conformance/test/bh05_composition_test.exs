Code.require_file("../../bh-05/composition-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.CompositionTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.CompositionFixtures, as: F
  alias BlazeX.UITree.{Composition, Node}
  alias BlazeX.Renderer.{Context, Headless}

  defp run(ref, graph, boundary \\ F.boundary()),
    do: Composition.evaluate("example", 1, ref, graph, boundary)

  test "all seven semantic kinds and complete intent match an independent public headless oracle" do
    assert {:ok, result} = run("surface", F.controls())
    assert result.output == F.oracle()

    {:ok, nodes} = Node.preorder(result.output.document.root)

    assert Enum.map(nodes, & &1.kind) == [
             :surface,
             :group,
             :action,
             :field,
             :collection,
             :selection,
             :text
           ]

    {:ok, context} = Context.new(result.output.document.root.identity, 0, :mount)
    assert {:ok, _, actual} = Headless.mount(result.output, context)
    assert {:ok, _, ^actual} = Headless.mount(F.oracle(), context)
    for _ <- 1..20, do: assert(run("surface", F.controls()) == {:ok, result})
    IO.puts("COMPOSITION_OUTPUT_SHA256 " <> result.output_digest)
    IO.puts("COMPOSITION_TRACE_SHA256 " <> result.trace_digest)
    IO.puts("COMPOSITION_HEADLESS_SHA256 " <> actual.value.digest)
  end

  test "contextual default and named slots repeat with stable keys and no implicit skipping" do
    assert {:ok, result} = run("shell", F.contextual())

    assert Enum.map(result.output.document.root.children, & &1.content) == [
             "Item 2",
             "Item 1",
             "Item 3"
           ]

    assert Enum.count(result.trace, &(&1.event == :invocation_enter)) == 4
    assert Enum.count(result.trace, &(&1.event == :slot_expansion)) == 3
    for _ <- 1..20, do: assert(run("shell", F.contextual()) == {:ok, result})
    IO.puts("COMPOSITION_SLOTS_OUTPUT_SHA256 " <> result.output_digest)
    IO.puts("COMPOSITION_SLOTS_TRACE_SHA256 " <> result.trace_digest)
    bad = put_in(F.contextual(), ["shell", :slots, "default"], [])
    assert {:error, %{code: :invocation}} = run("shell", bad)
    bad = put_in(F.contextual(), ["body", :props], %{"title" => {:caller, "missing"}})
    assert {:error, %{code: :lexical_prop}} = run("shell", bad)
    [entry | _] = F.contextual()["shell"].slots["default"]
    duplicate = put_in(F.contextual(), ["shell", :slots, "default"], [entry, entry])
    assert {:error, %{code: :invocation}} = run("shell", duplicate)

    assert {:error, %{code: :invocation}} =
             run("shell", F.contextual(), %{kind: :host, root: "example", owner: "adapter"})
  end

  test "exact invocation, node and depth limits are enforced before callback evaluation" do
    # 1 root + 127 child callbacks passes; record reuse in another branch exceeds
    # invocation count without exceeding the separate graph-record limit.
    leaves =
      for n <- 1..126,
          into: %{},
          do: {"n#{n}", %{F.spec("group") | public_id: "n#{n}", key: "n#{n}"}}

    root = %{F.spec("group", ["branch" | Enum.sort(Map.keys(leaves))]) | public_id: "root"}

    graph =
      leaves
      |> Map.put("root", root)
      |> Map.put("branch", %{F.spec("group") | public_id: "branch"})

    assert {:ok, _} = run("root", graph)
    assert {:error, %{code: :limit}} = run("root", put_in(graph, ["branch", :children], ["n1"]))

    assert {:ok, result} =
             run("inert", F.inert(255), %{kind: :host, root: "example", owner: "adapter"})

    {:ok, nodes} = Node.preorder(result.output.document.root)
    assert length(nodes) == 256

    assert {:error, %{code: :limit}} =
             run("inert", F.inert(256), %{kind: :host, root: "example", owner: "adapter"})

    deep =
      Map.new(0..12, fn n ->
        {"n#{n}",
         %{F.spec("group", if(n == 12, do: [], else: ["n#{n + 1}"])) | public_id: "n#{n}"}}
      end)

    assert {:ok, _} = run("n0", deep)
    deep = deep |> put_in(["n12", :children], ["n13"]) |> Map.put("n13", F.spec("group"))
    assert {:error, %{code: :limit}} = run("n0", deep)
  end

  test "public facade rejects process, message, renderer and dynamic callback dependencies at compile time" do
    for {body, index} <-
          Enum.with_index([
            "send(self(), :work)",
            "Process.put(:x, 1)",
            "BlazeX.Renderer.Headless.capabilities()",
            "apply(input.props[\"module\"], :run, [])",
            "input.props[\"callback\"].()"
          ]) do
      assert_raise CompileError, "BH-05 authoring: forbidden_dependency", fn ->
        Code.compile_string(
          "defmodule BlazeX.BH05.InvalidComposition#{index} do use BlazeX.Component, role: :pure, schema: [props: [], slots: []]; def render(input) do _ = input; #{body} end end"
        )
      end
    end

    refute_received :work
  end
end
