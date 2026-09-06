defmodule BlazeX.NativeSpike.Wire do
  @moduledoc "Closed BXN1 experiment protocol for complete native-control batches."

  alias BlazeX.NativeSpike.{Batch, Node}

  @max_nodes 128
  @max_depth 32
  @fields 14

  def encode(%Batch{} = batch) do
    header = [
      "BXN1",
      batch.generation,
      batch.revision,
      batch.transition,
      batch.digest,
      hex(inspect(batch.owner, limit: :infinity))
    ]

    records =
      case batch.root do
        nil -> []
        root -> encode_node(root, 0)
      end

    ([Enum.join(header, "\t")] ++ records ++ ["END"])
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  def decode(value) when is_binary(value) do
    with {:ok, lines} <- lines(value),
         {:ok, header, node_lines} <- header(lines),
         {:ok, records} <- decode_nodes(node_lines),
         :ok <- bounds(records) do
      {:ok, %{header: header, records: records}}
    end
  end

  def decode(_value), do: {:error, :invalid_native_wire}

  defp encode_node(%Node{} = node, depth) do
    accessible = node.attributes.accessibility
    layout = node.attributes.layout

    record = [
      "NODE",
      depth,
      node.id,
      node.kind,
      hex(node.text || ""),
      (accessible && accessible.role) || :none,
      hex((accessible && accessible.name) || ""),
      hex(encode_pairs((accessible && accessible.states) || %{})),
      hex(encode_relationships((accessible && accessible.relationships) || %{})),
      (layout && layout.mode) || :none,
      hex(encode_focus(node.focus)),
      hex(encode_selection(node.selection)),
      hex(node.listeners |> Enum.map(& &1.semantic) |> Enum.join(",")),
      length(node.children)
    ]

    [Enum.join(record, "\t") | Enum.flat_map(node.children, &encode_node(&1, depth + 1))]
  end

  defp lines(value) do
    case String.split(value, "\n", trim: true) do
      [] -> {:error, :empty_native_wire}
      lines -> {:ok, lines}
    end
  end

  defp header([first | rest]) do
    case String.split(first, "\t") do
      ["BXN1", generation, revision, transition, digest, owner]
      when transition in ["mount", "update", "replace", "dispose"] ->
        with {generation, ""} <- Integer.parse(generation),
             {revision, ""} <- Integer.parse(revision),
             true <- generation > 0 and revision >= 0,
             true <- Regex.match?(~r/^[0-9a-f]{64}$/, digest),
             {:ok, _owner} <- unhex(owner),
             true <- List.last(rest) == "END" do
          {:ok,
           %{
             generation: generation,
             revision: revision,
             transition: String.to_existing_atom(transition),
             digest: digest
           }, Enum.drop(rest, -1)}
        else
          _ -> {:error, :invalid_native_header}
        end

      _ ->
        {:error, :invalid_native_header}
    end
  end

  defp header(_lines), do: {:error, :invalid_native_header}

  defp decode_nodes(lines) do
    Enum.reduce_while(lines, {:ok, []}, fn line, {:ok, records} ->
      case String.split(line, "\t") do
        fields when length(fields) == @fields and hd(fields) == "NODE" ->
          [
            _,
            depth,
            id,
            kind,
            text,
            role,
            name,
            states,
            relationships,
            layout,
            focus,
            selection,
            listeners,
            children
          ] = fields

          with {depth, ""} <- Integer.parse(depth),
               true <- kind in Enum.map(BlazeX.UITree.Node.kinds(), &Atom.to_string/1),
               true <-
                 role in Enum.map(
                   [:none | BlazeX.UITree.Accessibility.roles()],
                   &Atom.to_string/1
                 ),
               true <- layout in ["none", "stack"],
               {children, ""} <- Integer.parse(children),
               true <- children >= 0,
               {:ok, decoded} <-
                 decode_hex_fields([
                   text,
                   name,
                   states,
                   relationships,
                   focus,
                   selection,
                   listeners
                 ]) do
            record = %{
              depth: depth,
              id: id,
              kind: kind,
              role: role,
              layout: layout,
              children: children,
              values: decoded
            }

            {:cont, {:ok, [record | records]}}
          else
            _ -> {:halt, {:error, :invalid_native_node}}
          end

        _ ->
          {:halt, {:error, :unknown_native_record}}
      end
    end)
    |> case do
      {:ok, records} -> {:ok, Enum.reverse(records)}
      error -> error
    end
  end

  defp bounds(records) do
    cond do
      length(records) > @max_nodes ->
        {:error, :native_node_limit_exceeded}

      Enum.any?(records, &(&1.depth > @max_depth or &1.depth < 0)) ->
        {:error, :native_depth_limit_exceeded}

      Enum.any?(records, fn record -> Enum.any?(record.values, &(byte_size(&1) > 4_096)) end) ->
        {:error, :native_value_limit_exceeded}

      records != [] and hd(records).depth != 0 ->
        {:error, :invalid_native_root}

      true ->
        :ok
    end
  end

  defp decode_hex_fields(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, decoded} ->
      case unhex(value) do
        {:ok, item} -> {:cont, {:ok, [item | decoded]}}
        :error -> {:halt, {:error, :invalid_native_hex}}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp encode_pairs(values),
    do: values |> Enum.sort() |> Enum.map_join(",", fn {key, value} -> "#{key}=#{value}" end)

  defp encode_relationships(values) do
    values
    |> Enum.sort()
    |> Enum.map_join(",", fn {key, ids} -> "#{key}=#{Enum.join(ids, "|")}" end)
  end

  defp encode_focus(nil), do: ""

  defp encode_focus(value),
    do: Enum.join([value.behavior, value.order, value.auto_focus, value.restore, value.wrap], ",")

  defp encode_selection(nil), do: ""
  defp encode_selection(value), do: "#{value.kind}:#{inspect(value.value, limit: :infinity)}"
  defp hex(value), do: value |> to_string() |> Base.encode16(case: :lower)
  defp unhex(value), do: Base.decode16(value, case: :lower)
end
