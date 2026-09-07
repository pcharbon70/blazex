defmodule BlazeX.Renderer.DOM.Retained do
  @moduledoc "Versioned, bounded immutable projection indexes; no browser state."
  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.Context
  alias BlazeX.Renderer.DOM.{Batch, Portable, Projection, ProtocolV2}
  alias BlazeX.Renderer.DOM.Protocol.Codec
  alias BlazeX.Renderer.DOM.ProtocolV2.IntentData
  import Codec, only: [require!: 1, require!: 2]
  @enforce_keys [:owner, :generation, :root, :nodes, :order, :fingerprint]
  defstruct [:owner, :generation, :root, :nodes, :order, :fingerprint, version: 1]
  @relationships ~w(aria-labelledby aria-describedby aria-controls aria-owns aria-errormessage)

  def check_input(output) do
    try do
      tree_bound!(semantic_root(output), 0, 0)
      bounded!(output, 0, 65_536)
      :ok
    rescue
      _ -> {:error, "invalid-identity"}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def from_output(output, %Context{} = context) do
    try do
      tree_bound!(semantic_root(output), 0, 0)
      bounded!(output, 0, 65_536)
      require!(Identity.valid?(context.owner), "invalid-identity")

      case Batch.project(output, context) do
        {:ok, batch} ->
          require!(batch.root.id == Portable.id(context.owner), "ownership")
          {nodes, _} = flatten(batch.root, nil, %{}, 0)
          new(context.owner, batch.root.id, nodes)

        _ ->
          {:error, "invalid-identity"}
      end
    rescue
      _ -> {:error, "invalid-identity"}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def new(owner, root, nodes) do
    try do
      require!(Identity.valid?(owner), "invalid-identity")
      require!(is_map(nodes) and map_size(nodes) in 1..128, "limit")
      require!(root == Portable.id(owner), "ownership")
      {order, visited} = walk(root, nil, nodes, [], MapSet.new(), 0)
      require!(MapSet.size(visited) == map_size(nodes), "invalid-identity")

      Enum.each(order, fn id ->
        node = nodes[id]

        Enum.each(node["attributes"], fn cell ->
          if cell["name"] in @relationships do
            targets = String.split(cell["value"], " ")

            require!(
              targets != [] and Enum.uniq(targets) == targets and
                Enum.all?(targets, &Map.has_key?(nodes, &1)),
              "missing-target"
            )
          end
        end)

        Enum.each(IntentData.unpack(node["listeners"]) || [], fn listener ->
          require!(portable_id(listener["source"]) == id, "ownership")
          owner_id = portable_id(listener["owner"])
          require!(Map.has_key?(nodes, owner_id), "ownership")
        end)
      end)

      require!(
        Enum.reduce(order, 0, &(&2 + IntentData.count(nodes[&1]["listeners"]))) <= 256,
        "limit"
      )

      fingerprint = Codec.digest(%{"root" => root, "nodes" => Enum.map(order, &nodes[&1])})

      {:ok,
       %__MODULE__{
         owner: owner,
         generation: owner.generation,
         root: root,
         nodes: nodes,
         order: order,
         fingerprint: fingerprint
       }}
    rescue
      _ -> {:error, "incompatible-state"}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def validate(%__MODULE__{version: 1} = state) do
    with {:ok, rebuilt} <- new(state.owner, state.root, state.nodes) do
      if rebuilt == state, do: :ok, else: {:error, "incompatible-state"}
    end
  end

  def validate(_), do: {:error, "incompatible-state"}

  def wire(state),
    do: %{
      "root" => state.root,
      "nodes" => Enum.map(state.order, &state.nodes[&1]),
      "fingerprint" => state.fingerprint
    }

  def owner_token(owner),
    do:
      "root-" <>
        binary_part(
          Codec.digest(%{
            "identity" => IntentData.pack(Portable.identity(%{owner | generation: 1}))
          }),
          0,
          24
        )

  def listener_ids(state) do
    Enum.flat_map(state.order, fn id ->
      Enum.map(IntentData.unpack(state.nodes[id]["listeners"]) || [], fn listener ->
        "bl-" <>
          binary_part(
            Codec.digest(%{"target" => id, "intent" => IntentData.pack(listener)}),
            0,
            24
          )
      end)
    end)
  end

  defp portable_id(wire),
    do:
      "bx-" <>
        binary_part(
          Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(wire, [:deterministic])),
            case: :lower
          ),
          0,
          24
        )

  defp flatten(%Projection{version: 1} = node, parent, nodes, depth) do
    require!(depth <= 32 and map_size(nodes) < 128, "limit")
    require!(not Map.has_key?(nodes, node.id), "invalid-identity")
    wire = Projection.to_wire(%{node | children: []})

    value = %{
      "id" => node.id,
      "parent" => parent,
      "children" => Enum.map(node.children, & &1.id),
      "tag" => node.tag,
      "text" => node.text,
      "attributes" => cells(node.attributes),
      "properties" => [],
      "focus" => IntentData.pack(wire["focus"]),
      "selection" => IntentData.pack(wire["selection"]),
      "listeners" =>
        if(wire["listeners"] == [], do: nil, else: IntentData.pack(wire["listeners"]))
    }

    Enum.reduce(node.children, {Map.put(nodes, node.id, value), depth}, fn child, {current, _} ->
      flatten(child, node.id, current, depth + 1)
    end)
  end

  defp flatten(_, _, _, _), do: throw({:protocol, "invalid-identity"})

  def cells(map),
    do: map |> Enum.sort() |> Enum.map(fn {k, v} -> %{"name" => k, "value" => v} end)

  def values(cells), do: Map.new(cells, &{&1["name"], &1["value"]})

  defp walk(id, parent, nodes, order, visited, depth) do
    require!(depth <= 32, "limit")
    require!(not MapSet.member?(visited, id) and Map.has_key?(nodes, id), "invalid-identity")
    node = nodes[id]

    require!(
      is_map(node) and
        Enum.sort(Map.keys(node)) ==
          Enum.sort(
            ~w(id parent children tag text attributes properties focus selection listeners)
          ),
      "incompatible-state"
    )

    require!(node["id"] == id and node["parent"] == parent, "ownership")

    require!(
      is_list(node["children"]) and length(node["children"]) <= 128 and
        Enum.uniq(node["children"]) == node["children"],
      "invalid-identity"
    )

    operation!(%{"type" => "create", "target" => id, "tag" => node["tag"], "text" => node["text"]})

    Enum.each([{"attributes", "attribute", 32}, {"properties", "property", 5}], fn {field, type,
                                                                                    max} ->
      list = node[field]
      require!(is_list(list) and length(list) <= max, "limit")

      names =
        Enum.map(list, fn cell ->
          require!(is_map(cell) and Enum.sort(Map.keys(cell)) == ~w(name value))
          require!(cell["value"] != nil)

          operation!(%{
            "type" => type,
            "target" => id,
            "name" => cell["name"],
            "old" => nil,
            "new" => cell["value"]
          })

          if type == "property",
            do:
              require!(
                if(cell["name"] == "value",
                  do: is_binary(cell["value"]),
                  else: is_boolean(cell["value"])
                )
              )

          cell["name"]
        end)

      require!(names == Enum.sort(Enum.uniq(names)))
    end)

    require!(
      values(node["attributes"])["data-bx-kind"] in ~w(text group action field selection collection surface),
      "invalid-identity"
    )

    Enum.each(~w(focus selection listeners), &require!(IntentData.valid?(&1, node[&1])))

    Enum.reduce(node["children"], {order ++ [id], MapSet.put(visited, id)}, fn child,
                                                                               {current, seen} ->
      walk(child, id, nodes, current, seen, depth + 1)
    end)
  end

  defp operation!(op) do
    case ProtocolV2.operation(Map.merge(op, %{"op_id" => 0, "depends" => []})) do
      {:ok, _} -> :ok
      {:error, code} -> throw({:protocol, code})
    end
  end

  # Bound arbitrary malformed terms before recursive semantic validation/lowering.
  defp semantic_root(%BlazeX.UITree.Node{} = root), do: root
  defp semantic_root(%BlazeX.UITree.Document{root: root}), do: root
  defp semantic_root(%BlazeX.UITree.IntentSet{document: document}), do: semantic_root(document)
  defp semantic_root(_), do: throw({:protocol, "invalid-identity"})

  defp tree_bound!(%BlazeX.UITree.Node{children: children}, count, depth) do
    require!(count < 128 and depth <= 32, "limit")
    require!(is_list(children), "invalid-identity")
    Enum.reduce(children, count + 1, &tree_bound!(&1, &2, depth + 1))
  end

  defp tree_bound!(_, _, _), do: throw({:protocol, "invalid-identity"})

  defp bounded!(_, depth, budget) when depth > 128 or budget <= 0, do: throw({:protocol, "limit"})
  defp bounded!([], _, budget), do: budget - 1

  defp bounded!([head | tail], depth, budget),
    do: bounded!(tail, depth, bounded!(head, depth + 1, budget - 1))

  defp bounded!(value, depth, budget) when is_map(value),
    do:
      Enum.reduce(Map.to_list(value), budget - 1, fn {k, v}, left ->
        bounded!(v, depth + 1, bounded!(k, depth + 1, left))
      end)

  defp bounded!(value, depth, budget) when is_tuple(value),
    do: bounded!(Tuple.to_list(value), depth + 1, budget - 1)

  defp bounded!(value, _, budget) when is_binary(value) do
    require!(byte_size(value) <= 4096 and String.valid?(value), "limit")
    budget - 1
  end

  defp bounded!(value, _, budget) when is_integer(value) do
    require!(:erlang.external_size(value) <= 4096, "limit")
    budget - 1
  end

  defp bounded!(value, _, budget) when is_atom(value) or is_float(value), do: budget - 1
  defp bounded!(_, _, _), do: throw({:protocol, "invalid-identity"})
end
