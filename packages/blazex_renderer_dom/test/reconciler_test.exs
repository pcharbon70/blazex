defmodule BlazeX.Renderer.DOM.ReconcilerTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.Node
  alias BlazeX.Renderer.Context
  alias BlazeX.Renderer.DOM.{ProtocolV2, Reconciler, Replay, Retained}
  alias BlazeX.Renderer.DOM.Protocol.Codec
  alias BlazeX.Renderer.DOM.ProtocolV2.IntentData

  defp tree(keys, generation \\ 1) do
    {:ok, owner} = Identity.new(:reconciler, generation)

    children =
      Enum.map(keys, fn {key, text} ->
        {:ok, id} = Identity.child(owner, key)
        {:ok, node} = Node.text(id, text, key: key)
        node
      end)

    {:ok, root} = Node.container(:group, owner, children)
    root
  end

  defp project(node) do
    {:ok, context} = Context.new(node.identity, 0, :mount)
    {:ok, retained} = Retained.from_output(node, context)
    retained
  end

  defp diff(old, next, kind \\ "patch", revision \\ 1) do
    {:ok, tx, context, decision} = Reconciler.transaction(old, next, kind, revision, 1)
    assert {:ok, ^next} = Replay.apply(old, tx, context, (next || old).owner)
    assert {:ok, _} = ProtocolV2.new(tx, context)
    assert {:ok, bytes} = Codec.encode(tx)
    assert {:ok, ^tx} = Codec.decode(bytes)
    {tx, decision}
  end

  test "initial and no-op have deterministic replay and dependency order" do
    next = project(tree(a: "A", b: "B"))
    {tx, _} = diff(nil, next, "initial", 0)

    assert Reconciler.transaction(nil, next, "initial", 0, 1) ==
             Reconciler.transaction(nil, next, "initial", 0, 1)

    for {op, index} <- Enum.with_index(tx["operations"]) do
      assert op["op_id"] == index
      assert op["depends"] == if(index == 0, do: [], else: [index - 1])
    end

    {noop, _} = diff(next, next)
    assert [%{"type" => "effect_barrier"}] = noop["operations"]
  end

  test "leaf updates and keyed reorder retain IDs without replacement" do
    old = project(tree(a: "A", b: "B", c: "C"))
    next = project(tree(c: "C", a: "new", b: "B"))
    {tx, %{replacements: []}} = diff(old, next)
    types = Enum.map(tx["operations"], & &1["type"])
    assert "move" in types and "text" in types
    refute Enum.any?(types, &(&1 in ~w(create remove)))
  end

  test "removal and insertion reuse the bounded topology" do
    diff(project(tree(a: "A", b: "B")), project(tree(c: "C", b: "B", d: "D")))
  end

  test "kind mismatch explicitly rematerializes subtree" do
    node = tree(a: "A", b: "B")
    old = project(node)
    next = project(%{node | kind: :surface})
    {tx, %{replacements: [root]}} = diff(old, next)
    assert root == old.root
    assert Enum.count(tx["operations"], &(&1["type"] == "remove")) == 3
  end

  test "generation replacement and disposal" do
    old = project(tree([a: "A"], 1))
    next = project(tree([a: "B"], 2))
    diff(old, next, "replace")
    {tx, _} = diff(next, nil, "dispose", 2)
    assert tx["operations"] == []
    assert {:error, "ownership"} = Reconciler.transaction(old, next, "patch", 1, 1)
  end

  test "v2 preserves all layout and relationship names plus property cells" do
    old = project(tree(a: "A"))
    child = List.last(old.order)

    attrs =
      old.nodes[old.root]["attributes"]
      |> Retained.values()
      |> Map.merge(%{"aria-controls" => child, "data-bx-layout-width" => "fill"})

    nodes =
      old.nodes
      |> put_in([old.root, "attributes"], Retained.cells(attrs))
      |> put_in([child, "properties"], Retained.cells(%{"value" => "typed", "checked" => false}))

    {:ok, next} = Retained.new(old.owner, old.root, nodes)
    {tx, _} = diff(old, next)
    assert Enum.any?(tx["operations"], &(&1["type"] == "property"))

    invalid =
      put_in(
        nodes[old.root]["attributes"],
        Retained.cells(Map.put(attrs, "aria-controls", "bx-" <> String.duplicate("0", 24)))
      )

    assert {:error, "missing-target"} = Retained.new(old.owner, old.root, invalid)
  end

  test "complete focus and signed selection data survive canonical intent cells" do
    old = project(tree(a: "A"))

    focus = %{
      "behavior" => "target",
      "order" => 2,
      "auto_focus" => true,
      "restore" => "none",
      "wrap" => false
    }

    selection = %{
      "kind" => "single",
      "value" => %{"type" => "integer", "value" => -9_007_199_254_741_000}
    }

    cell = IntentData.pack(selection)
    assert IntentData.valid?("selection", cell)
    assert IntentData.unpack(cell) == selection

    nodes =
      old.nodes
      |> put_in([old.root, "focus"], IntentData.pack(focus))
      |> put_in([old.root, "selection"], cell)

    {:ok, next} = Retained.new(old.owner, old.root, nodes)
    diff(old, next)
    diff(next, old)
    refute IntentData.valid?("focus", IntentData.pack(Map.put(focus, "unexpected", true)))
  end

  test "duplicate identity, invalid parent and corrupt state reject atomically" do
    root = tree(a: "A")
    {:ok, context} = Context.new(root.identity, 0, :mount)

    assert {:error, "invalid-identity"} =
             Retained.from_output(%{root | children: root.children ++ root.children}, context)

    old = project(root)
    child = List.last(old.order)

    assert {:error, "ownership"} =
             Retained.new(old.owner, old.root, put_in(old.nodes, [child, "parent"], nil))

    assert {:error, "incompatible-state"} =
             Reconciler.transaction(%{old | fingerprint: "bad"}, old, "patch", 1, 1)

    assert Retained.validate(old) == :ok
  end

  test "missing explicit key retains mandatory path identity; key types remain distinct" do
    root = tree([{:a, "atom"}, {"a", "string"}, {-1, "integer"}])
    unkeyed = %{root | children: Enum.map(root.children, &%{&1 | key: nil})}
    assert project(root) == project(unkeyed)
    assert length(Enum.uniq(project(root).order)) == 4
  end

  test "node and operation limits reject without a partial transaction" do
    root = tree(Enum.map(1..128, &{&1, "text"}))
    {:ok, context} = Context.new(root.identity, 0, :mount)
    assert {:error, "limit"} = Retained.from_output(root, context)
    old = project(tree(Enum.map(1..127, &{&1, "text"})))

    nodes =
      Map.new(old.nodes, fn {id, node} ->
        {id,
         Map.put(
           node,
           "attributes",
           Retained.cells(
             Map.merge(Retained.values(node["attributes"]), %{
               "aria-label" => "a",
               "aria-description" => "b",
               "aria-live" => "polite"
             })
           )
         )}
      end)

    {:ok, next} = Retained.new(old.owner, old.root, nodes)
    assert {:error, "limit"} = Reconciler.transaction(nil, next, "initial", 0, 1)
    assert Retained.validate(old) == :ok
  end

  test "120 generated keyed edits reconstruct exactly and replay deterministically" do
    for seed <- 1..120 do
      keys = Enum.to_list(1..12)
      old = project(tree(Enum.map(keys, &{&1, "v#{&1}"})))

      next_keys =
        keys |> Enum.reject(&(rem(&1 + seed, 5) == 0)) |> Enum.sort_by(&rem(&1 * 7 + seed, 17))

      next = project(tree(Enum.map(next_keys ++ [100 + seed], &{&1, "v#{&1 + rem(seed, 3)}"})))
      diff(old, next)

      assert Reconciler.transaction(old, next, "patch", 1, seed) ==
               Reconciler.transaction(old, next, "patch", 1, seed)
    end
  end
end
