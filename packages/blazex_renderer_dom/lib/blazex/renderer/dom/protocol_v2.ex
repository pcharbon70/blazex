defmodule BlazeX.Renderer.DOM.ProtocolV2 do
  @moduledoc """
  Strict immutable internal render records and pure topology preflight.
  This module neither reconciles semantic trees nor executes transactions.
  Value old/new assertions are data; materialized-value checks belong to Phase 4.
  """
  alias BlazeX.Renderer.DOM.Protocol.Codec
  alias BlazeX.Renderer.DOM.ProtocolV2.{Schema, IntentData}
  import Codec, only: [require!: 1, require!: 2]
  @enforce_keys [:record]
  defstruct [:record]
  @protocol "blazex.dom-transaction/2"
  @schema "2.0.0"

  def limits,
    do: %{
      depth: 32,
      nodes: 128,
      operations: 512,
      listeners: 256,
      attributes: 32,
      text_bytes: 4096,
      value_bytes: 2048,
      queue: 64,
      message_bytes: 131_072
    }

  def compatibility(@protocol, @schema, ["atomic", "ordered"]),
    do: {:ok, %{protocol: @protocol, schema: @schema, outcome: :compatible}}

  def compatibility(_, _, _), do: {:error, "incompatible"}

  def seal(record) when is_map(record) do
    payload = Map.delete(record, "digest")
    Map.put(payload, "digest", Codec.digest(payload))
  end

  def new(record, context) do
    try do
      Codec.encode!(record)
      Codec.encode!(context)

      require!(
        is_map(record) and record["protocol"] == @protocol and record["schema"] == @schema,
        "incompatible"
      )

      require!(Schema.valid?(record, Map.get(Schema.schemas(), record["record"], %{})))
      require!(Schema.valid?(context, Schema.schemas()["context"]))

      if record["record"] == "transaction" do
        preflight(record, context)
        require!(record["digest"] == Codec.digest(Map.delete(record, "digest")))
      else
        require!(context["transaction"] != nil)

        require!(
          context["transaction"]["owner"] == context["owner"] and
            context["transaction"]["generation"] == context["generation"],
          "ownership"
        )

        Enum.each(
          ~w(owner generation root base_revision target_revision transaction_id digest),
          &require!(record[&1] == context["transaction"][&1], "ownership")
        )

        if record["record"] == "ack" do
          failed = record["state"] in ["rejected", "rolled-back", "fallback"]
          require!(failed == (record["diagnostic"] != nil))

          if not failed do
            require!(
              context["transaction"]["protocol"] == record["protocol"] and
                context["transaction"]["schema"] == record["schema"],
              "incompatible"
            )

            require!(
              record["base_revision"] == context["revision"] and
                record["target_revision"] == context["revision"] + 1,
              "stale"
            )
          end

          require!(record["state"] != "disposed" or context["transaction"]["kind"] == "dispose")
          require!(record["state"] != "committed" or context["transaction"]["kind"] != "dispose")
        else
          require!(
            record["operation_id"] == nil or
              record["operation_id"] < context["transaction"]["operation_count"]
          )
        end
      end

      {:ok, %__MODULE__{record: record}}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def operation(record) do
    try do
      Codec.encode!(record)

      require!(
        Schema.valid?(
          record,
          Schema.schemas()["transaction"]["properties"]["operations"]["items"]
        )
      )

      require!(
        unique?(record["depends"]) and record["depends"] == Enum.sort(record["depends"]) and
          Enum.all?(record["depends"], &(&1 < record["op_id"]))
      )

      {:ok, %__MODULE__{record: record}}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def to_wire(%__MODULE__{record: record}), do: record
  defp unique?(values), do: length(Enum.uniq(values)) == length(values)
  defp target!(nodes, id), do: require!(Map.has_key?(nodes, id), "missing-target")
  defp leaf!(nodes, id), do: require!(id not in Map.values(nodes))

  defp topology!(nodes) do
    require!(map_size(nodes) <= 128, "limit")
    Enum.each(Map.keys(nodes), &ancestry!(nodes, &1, MapSet.new(), 0))
  end

  defp ancestry!(_, nil, _, _), do: :ok

  defp ancestry!(nodes, cursor, seen, depth) do
    target!(nodes, cursor)
    require!(not MapSet.member?(seen, cursor))
    require!(depth <= 32, "limit")
    ancestry!(nodes, nodes[cursor], MapSet.put(seen, cursor), depth + 1)
  end

  defp location!(nodes, op) do
    if op["parent"] != nil, do: target!(nodes, op["parent"])
    require!(op["target"] != op["parent"] and op["anchor"] != op["target"])

    if op["anchor"] != nil do
      target!(nodes, op["anchor"])
      require!(nodes[op["anchor"]] == op["parent"])
    end
  end

  defp preflight(tx, context) do
    require!(tx["features"] == ["atomic", "ordered"], "incompatible")

    require!(
      tx["owner"] == context["owner"] and tx["generation"] == context["generation"],
      "ownership"
    )

    require!(not context["disposed"], "disposed-root")

    require!(
      tx["base_revision"] == context["revision"] and
        tx["target_revision"] == context["revision"] + 1,
      "stale"
    )

    require!(tx["transaction_id"] not in context["seen"], "duplicate")

    require!(
      unique?(Enum.map(context["nodes"], & &1["id"])) and unique?(context["listeners"]) and
        unique?(context["seen"]),
      "duplicate"
    )

    nodes = Map.new(context["nodes"], &{&1["id"], &1["parent"]})
    topology!(nodes)

    require!(
      if context["root"] == nil,
        do: map_size(nodes) == 0,
        else:
          Map.has_key?(nodes, context["root"]) and nodes[context["root"]] == nil and
            Enum.count(Map.values(nodes), &is_nil/1) == 1
    )

    if tx["kind"] == "initial" do
      require!(
        context["root"] == nil and context["revision"] == 0 and map_size(nodes) == 0,
        "stale"
      )
    else
      require!(context["root"] != nil, "missing-target")
    end

    if tx["kind"] in ["patch", "dispose"],
      do: require!(tx["root"] == context["root"], "ownership")

    if tx["kind"] == "dispose" do
      require!(tx["operations"] == [])
    else
      require!(tx["operations"] != [])

      {nodes, detached, _listeners} =
        tx["operations"]
        |> Enum.with_index()
        |> Enum.reduce({nodes, MapSet.new(), length(context["listeners"])}, fn {op, index},
                                                                               state ->
          require!(
            op["op_id"] == index and unique?(op["depends"]) and
              op["depends"] == Enum.sort(op["depends"]) and
              Enum.all?(op["depends"], &(&1 < index))
          )

          next = apply_operation(op, index, length(tx["operations"]), state)
          topology!(elem(next, 0))
          next
        end)

      require!(Map.has_key?(nodes, tx["root"]) and nodes[tx["root"]] == nil, "missing-target")
      require!(Enum.count(Map.values(nodes), &is_nil/1) == 1 and MapSet.size(detached) == 0)
    end
  end

  defp apply_operation(%{"type" => "create"} = op, _, _, {nodes, detached, listeners}) do
    require!(not Map.has_key?(nodes, op["target"]), "duplicate")
    {Map.put(nodes, op["target"], nil), MapSet.put(detached, op["target"]), listeners}
  end

  defp apply_operation(%{"type" => "effect_barrier"} = op, index, count, state) do
    require!(index == count - 1 and unique?(op["resources"]))
    state
  end

  defp apply_operation(op, _, _, {nodes, detached, listeners}) do
    id = op["target"]
    target!(nodes, id)

    case op["type"] do
      type when type in ["insert", "move"] ->
        location!(nodes, op)

        require!(
          if type == "insert",
            do: MapSet.member?(detached, id),
            else: not MapSet.member?(detached, id)
        )

        require!(nodes[id] == op["old_parent"], "stale")
        {Map.put(nodes, id, op["parent"]), MapSet.delete(detached, id), listeners}

      "remove" ->
        leaf!(nodes, id)
        require!(nodes[id] == op["old_parent"], "stale")
        {Map.delete(nodes, id), MapSet.delete(detached, id), listeners}

      "replace" ->
        leaf!(nodes, id)
        target!(nodes, op["value"])
        location!(nodes, op)

        require!(
          MapSet.member?(detached, op["value"]) and id != op["value"] and
            nodes[id] == op["parent"]
        )

        require!(op["anchor"] != op["value"] and op["parent"] != op["value"])

        {nodes |> Map.delete(id) |> Map.put(op["value"], op["parent"]),
         detached |> MapSet.delete(id) |> MapSet.delete(op["value"]), listeners}

      "intent" ->
        Enum.each([op["old"], op["new"]], &require!(IntentData.valid?(op["name"], &1)))

        count =
          if op["name"] == "listeners",
            do: listeners - IntentData.count(op["old"]) + IntentData.count(op["new"]),
            else: listeners

        require!(count >= 0 and count <= 256, "limit")
        {nodes, detached, count}

      "property" ->
        require!(
          Enum.all?([op["old"], op["new"]], fn value ->
            is_nil(value) or
              if op["name"] == "value", do: is_binary(value), else: is_boolean(value)
          end)
        )

        {nodes, detached, listeners}

      _ ->
        {nodes, detached, listeners}
    end
  end
end
