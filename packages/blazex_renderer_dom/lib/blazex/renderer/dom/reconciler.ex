defmodule BlazeX.Renderer.DOM.Reconciler do
  @moduledoc "Bounded keyed diff with replay-before-publication and explicit replacement."
  alias BlazeX.Renderer.DOM.{ProtocolV2, Replay, Retained}
  alias BlazeX.Renderer.DOM.Protocol.Codec
  import Codec, only: [require!: 2]

  def transaction(old, next, kind, revision, attempt) do
    try do
      require!(kind in ~w(initial patch replace dispose), "incompatible-state")
      require!(is_integer(attempt) and attempt in 1..9_007_199_254_740_991, "limit")

      Enum.each([old, next], fn state ->
        if state != nil, do: require!(Retained.validate(state) == :ok, "incompatible-state")
      end)

      transition!(old, next, kind)
      owner = (next || old).owner
      context = context(old, owner, revision)
      {ops, replacements} = if kind == "dispose", do: {[], []}, else: diff(old, next)
      root = (next || old).root

      payload = %{
        "record" => "transaction",
        "protocol" => "blazex.dom-transaction/2",
        "schema" => "2.0.0",
        "owner" => Retained.owner_token(owner),
        "generation" => owner.generation,
        "root" => root,
        "base_revision" => revision,
        "target_revision" => revision + 1,
        "kind" => kind,
        "features" => ["atomic", "ordered"],
        "operations" => ops
      }

      id = "tx-" <> binary_part(Codec.digest(Map.put(payload, "attempt", attempt)), 0, 24)
      tx = payload |> Map.put("transaction_id", id) |> ProtocolV2.seal()

      with {:ok, reconstructed} <- Replay.apply(old, tx, context, owner) do
        require!(reconstructed == next, "ordering")
        {:ok, tx, context, %{replacements: replacements, operations: length(ops)}}
      end
    rescue
      _ -> {:error, "incompatible-state"}
    catch
      {:protocol, code} -> {:error, code}
    end
  end

  def context(old, owner, revision) do
    %{
      "owner" => Retained.owner_token(owner),
      "generation" => owner.generation,
      "revision" => revision,
      "root" => old && old.root,
      "disposed" => false,
      "nodes" =>
        if(old, do: Enum.map(old.order, &Map.take(old.nodes[&1], ~w(id parent))), else: []),
      "listeners" => if(old, do: Retained.listener_ids(old), else: []),
      "seen" => [],
      "transaction" => nil
    }
  end

  def attempt_header(tx),
    do:
      tx
      |> Map.take(
        ~w(protocol schema owner generation root base_revision target_revision transaction_id digest kind)
      )
      |> Map.put("operation_count", length(tx["operations"]))

  defp transition!(nil, %Retained{}, "initial"), do: :ok
  defp transition!(%Retained{}, nil, "dispose"), do: :ok

  defp transition!(%Retained{} = old, %Retained{} = next, "patch"),
    do: require!(old.owner == next.owner, "ownership")

  defp transition!(%Retained{} = old, %Retained{} = next, "replace"),
    do: require!(%{old.owner | generation: old.generation + 1} == next.owner, "ownership")

  defp transition!(_, _, _), do: throw({:protocol, "incompatible-state"})

  defp diff(old, next) do
    previous = if old, do: old.nodes, else: %{}
    old_order = if old, do: old.order, else: []

    incompatible =
      Enum.filter(next.order, fn id ->
        Map.has_key?(previous, id) and
          (previous[id]["tag"] != next.nodes[id]["tag"] or
             Retained.values(previous[id]["attributes"])["data-bx-kind"] !=
               Retained.values(next.nodes[id]["attributes"])["data-bx-kind"])
      end)

    Enum.each(next.order, fn id ->
      if Map.has_key?(previous, id),
        do: require!(previous[id]["parent"] == next.nodes[id]["parent"], "ownership")
    end)

    removed =
      old_order
      |> Enum.filter(fn id ->
        not Map.has_key?(next.nodes, id) or beneath?(id, previous, incompatible)
      end)
      |> MapSet.new()

    builder = {[], Replay.model(old)}

    builder =
      old_order
      |> Enum.reverse()
      |> Enum.filter(&MapSet.member?(removed, &1))
      |> Enum.reduce(builder, fn id, acc ->
        node = previous[id]

        acc =
          if node["listeners"] != nil,
            do:
              emit(acc, %{
                "type" => "intent",
                "target" => id,
                "name" => "listeners",
                "old" => node["listeners"],
                "new" => nil
              }),
            else: acc

        emit(acc, %{"type" => "remove", "target" => id, "old_parent" => node["parent"]})
      end)

    created =
      Enum.filter(next.order, &(not Map.has_key?(previous, &1) or MapSet.member?(removed, &1)))

    builder =
      Enum.reduce(created, builder, fn id, acc ->
        node = next.nodes[id]

        emit(acc, %{
          "type" => "create",
          "target" => id,
          "tag" => node["tag"],
          "text" => node["text"]
        })
      end)

    builder =
      if next.root in created,
        do:
          emit(builder, %{
            "type" => "insert",
            "target" => next.root,
            "parent" => nil,
            "anchor" => nil,
            "old_parent" => nil
          }),
        else: builder

    builder =
      Enum.reduce(next.order, builder, fn parent, acc ->
        {acc, _} =
          next.nodes[parent]["children"]
          |> Enum.reverse()
          |> Enum.reduce({acc, nil}, fn id, {current, anchor} ->
            {_, model} = current
            siblings = model.nodes[parent]["children"]
            position = Enum.find_index(siblings, &(&1 == id))
            adjacent = position != nil and Enum.at(siblings, position + 1) == anchor

            current =
              cond do
                id in created ->
                  emit(current, %{
                    "type" => "insert",
                    "target" => id,
                    "parent" => parent,
                    "anchor" => anchor,
                    "old_parent" => nil
                  })

                adjacent ->
                  current

                true ->
                  emit(current, %{
                    "type" => "move",
                    "target" => id,
                    "parent" => parent,
                    "anchor" => anchor,
                    "old_parent" => parent
                  })
              end

            {current, id}
          end)

        acc
      end)

    builder =
      Enum.reduce(next.order, builder, fn id, acc ->
        {_, model} = acc
        current = model.nodes[id]
        desired = next.nodes[id]

        acc =
          if current["text"] == desired["text"],
            do: acc,
            else:
              emit(acc, %{
                "type" => "text",
                "target" => id,
                "old" => current["text"],
                "new" => desired["text"]
              })

        acc =
          Enum.reduce([{"attributes", "attribute"}, {"properties", "property"}], acc, fn {field,
                                                                                          type},
                                                                                         current_acc ->
            before = Retained.values(current[field])
            after_values = Retained.values(desired[field])

            Enum.reduce(
              Enum.sort(Enum.uniq(Map.keys(before) ++ Map.keys(after_values))),
              current_acc,
              fn name, a ->
                if before[name] == after_values[name],
                  do: a,
                  else:
                    emit(a, %{
                      "type" => type,
                      "target" => id,
                      "name" => name,
                      "old" => before[name],
                      "new" => after_values[name]
                    })
              end
            )
          end)

        Enum.reduce(~w(focus selection listeners), acc, fn name, a ->
          if current[name] == desired[name],
            do: a,
            else:
              emit(a, %{
                "type" => "intent",
                "target" => id,
                "name" => name,
                "old" => current[name],
                "new" => desired[name]
              })
        end)
      end)

    {ops, _} =
      emit(builder, %{"type" => "effect_barrier", "barrier" => "post-commit", "resources" => []})

    {Enum.reverse(ops), incompatible}
  end

  defp beneath?(nil, _, _), do: false
  defp beneath?(id, nodes, roots), do: id in roots or beneath?(nodes[id]["parent"], nodes, roots)

  defp emit({ops, model}, value) do
    index = length(ops)
    require!(index < 512, "limit")

    op =
      Map.merge(value, %{"op_id" => index, "depends" => if(index == 0, do: [], else: [index - 1])})

    {[op | ops], Replay.step!(op, model)}
  end
end
