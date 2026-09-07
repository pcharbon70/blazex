defmodule BlazeX.Renderer.DOM.Replay do
  @moduledoc "Pure data reference applicator. Never mutates a browser DOM."
  alias BlazeX.Renderer.DOM.{ProtocolV2, Retained}
  import BlazeX.Renderer.DOM.Protocol.Codec, only: [require!: 2]
  def empty, do: %{root: nil, nodes: %{}}
  def model(nil), do: empty()
  def model(%Retained{} = state), do: %{root: state.root, nodes: state.nodes}

  def apply(old, tx, context, owner) do
    with {:ok, _} <- ProtocolV2.new(tx, context) do
      try do
        if tx["kind"] == "dispose" do
          {:ok, nil}
        else
          result = Enum.reduce(tx["operations"], model(old), &step!/2)
          require!(result.root == tx["root"], "ordering")
          Retained.new(owner, result.root, result.nodes)
        end
      rescue
        _ -> {:error, "ordering"}
      catch
        {:protocol, code} -> {:error, code}
      end
    end
  end

  def step!(%{"type" => "effect_barrier"}, state), do: state

  def step!(%{"type" => "create"} = op, state) do
    require!(not Map.has_key?(state.nodes, op["target"]), "duplicate")

    node = %{
      "id" => op["target"],
      "parent" => nil,
      "children" => [],
      "tag" => op["tag"],
      "text" => op["text"],
      "attributes" => [],
      "properties" => [],
      "focus" => nil,
      "selection" => nil,
      "listeners" => nil
    }

    %{state | nodes: Map.put(state.nodes, node["id"], node)}
  end

  def step!(op, state) do
    id = op["target"]
    require!(Map.has_key?(state.nodes, id), "missing-target")
    node = state.nodes[id]

    case op["type"] do
      "remove" ->
        require!(
          node["children"] == [] and node["listeners"] == nil and
            node["parent"] == op["old_parent"],
          "stale"
        )

        state = detach(state, id)
        %{state | nodes: Map.delete(state.nodes, id)}

      type when type in ["insert", "move"] ->
        require!(node["parent"] == op["old_parent"], "stale")
        state = detach(state, id)
        parent = op["parent"]
        state = put_in(state.nodes[id]["parent"], parent)

        if parent == nil do
          require!(op["anchor"] == nil and state.root == nil, "ordering")
          %{state | root: id}
        else
          children = state.nodes[parent]["children"]

          index =
            if op["anchor"] == nil,
              do: length(children),
              else: Enum.find_index(children, &(&1 == op["anchor"]))

          require!(index != nil, "ordering")
          put_in(state.nodes[parent]["children"], List.insert_at(children, index, id))
        end

      "text" ->
        require!(node["text"] == op["old"], "stale")
        put_in(state.nodes[id]["text"], op["new"])

      type when type in ["attribute", "property"] ->
        field = if type == "attribute", do: "attributes", else: "properties"
        values = Retained.values(node[field])
        require!(values[op["name"]] == op["old"], "stale")

        values =
          if op["new"] == nil,
            do: Map.delete(values, op["name"]),
            else: Map.put(values, op["name"], op["new"])

        put_in(state.nodes[id][field], Retained.cells(values))

      "intent" ->
        require!(node[op["name"]] == op["old"], "stale")
        put_in(state.nodes[id][op["name"]], op["new"])

      _ ->
        throw({:protocol, "ordering"})
    end
  end

  defp detach(state, id) do
    parent = state.nodes[id]["parent"]

    cond do
      parent != nil ->
        put_in(state.nodes[parent]["children"], List.delete(state.nodes[parent]["children"], id))

      state.root == id ->
        %{state | root: nil}

      true ->
        state
    end
  end
end
