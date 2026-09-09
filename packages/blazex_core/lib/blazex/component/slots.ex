defmodule BlazeX.Component.Slots do
  @moduledoc "Ordered, keyed, caller-owned slot descriptors. Never invokes content."
  alias BlazeX.Component.{Props, Schema}
  @options [:required, :min, :max, :props, :context, :key, :boundary, :doc]

  def declare(declarations) do
    if Schema.list?(declarations, 64) do
      Enum.reduce_while(declarations, {:ok, []}, fn item, {:ok, acc} ->
        case slot(item) do
          {:ok, slot} ->
            if Enum.any?(acc, &(&1.name == slot.name)),
              do: {:halt, Schema.error(:duplicate_slot, [])},
              else: {:cont, {:ok, acc ++ [slot]}}

          error ->
            {:halt, error}
        end
      end)
    else
      Schema.error(:invalid_slots_schema, [])
    end
  end

  defp slot({name, options}) do
    with true <- Schema.name?(name),
         true <- Keyword.keyword?(options),
         true <- length(Keyword.keys(options)) == length(Enum.uniq(Keyword.keys(options))),
         true <- Enum.all?(Keyword.keys(options), &(&1 in @options)),
         required <- Keyword.get(options, :required, false),
         true <- is_boolean(required),
         min <- Keyword.get(options, :min, if(required, do: 1, else: 0)),
         max <- Keyword.get(options, :max, 1),
         true <- is_integer(min) and is_integer(max) and min >= 0 and min <= max and max <= 256,
         true <- required == min > 0,
         key <- Keyword.get(options, :key, :required),
         true <- key in [:required, :optional],
         boundary <- Keyword.get(options, :boundary, :local),
         true <- boundary in [:host, :local],
         context <- Keyword.get(options, :context, {:record, []}),
         true <- Schema.valid?(context),
         true <- boundary == :local or Schema.host?(context),
         {:ok, props} <- Props.declare(Keyword.get(options, :props, [])),
         true <- boundary == :local or Enum.all?(props, &(&1.boundary == :host)),
         doc <- Keyword.get(options, :doc, ""),
         true <- is_binary(doc) and byte_size(doc) <= 4096 and String.valid?(doc) do
      {:ok,
       %{
         name: name,
         required: required,
         min: min,
         max: max,
         key: key,
         boundary: boundary,
         context: context,
         props: props,
         doc: doc
       }}
    else
      _ -> Schema.error(:invalid_slot_declaration, [])
    end
  end

  defp slot(_slot), do: Schema.error(:invalid_slot_declaration, [])

  def normalize(declarations, values, boundary) do
    with {:ok, slots} <- declare(declarations), true <- Schema.boundary?(boundary) do
      names = Enum.map(slots, & &1.name)

      if is_map(values) and not is_struct(values) and Enum.all?(Map.keys(values), &(&1 in names)) do
        Enum.reduce_while(slots, {:ok, []}, fn slot, {:ok, acc} ->
          case entries(slot, Map.get(values, slot.name, []), boundary) do
            {:ok, normalized} -> {:cont, {:ok, acc ++ [{slot.name, normalized}]}}
            error -> {:halt, error}
          end
        end)
      else
        Schema.error(:unknown_slot, [:slots])
      end
    else
      false -> Schema.error(:invalid_boundary, [])
      error -> error
    end
  end

  defp entries(slot, values, boundary) do
    path = [:slots, slot.name]

    cond do
      not Schema.list?(values, slot.max) ->
        Schema.error(:cardinality, path)

      length(values) < slot.min ->
        Schema.error(:cardinality, path)

      values != [] and slot.boundary == :local and boundary.kind != :local ->
        Schema.error(:local_only, path)

      true ->
        values
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {entry, index}, {:ok, acc} ->
          case entry(slot, entry, boundary, path ++ [index], index) do
            {:ok, normalized} ->
              if Enum.any?(acc, &(&1.key == normalized.key)),
                do: {:halt, Schema.error(:duplicate_key, path ++ [index])},
                else: {:cont, {:ok, acc ++ [normalized]}}

            error ->
              {:halt, error}
          end
        end)
    end
  end

  defp entry(slot, value, boundary, path, index) when is_map(value) and not is_struct(value) do
    allowed = ["key", "props", "context", "content"]
    key = Map.get(value, "key", if(slot.key == :optional, do: {:ordinal, index}, else: nil))

    valid_key =
      (is_binary(key) and byte_size(key) in 1..128 and String.valid?(key)) or
        (not Map.has_key?(value, "key") and key == {:ordinal, index})

    with true <- Enum.all?(Map.keys(value), &(&1 in allowed)),
         true <- valid_key,
         {:ok, props} <-
           Props.normalize_fields(
             slot.props,
             Map.get(value, "props", %{}),
             boundary,
             path ++ [:props]
           ),
         {:ok, context} <-
           Schema.normalize(
             slot.context,
             Map.get(value, "context", %{}),
             boundary,
             path ++ [:context]
           ),
         {:ok, content} <-
           content(slot.boundary, Map.get(value, "content"), boundary, path ++ [:content]) do
      {:ok, %{key: key, props: props, context: context, content: content}}
    else
      false -> Schema.error(:slot_entry, path)
      error -> error
    end
  end

  defp entry(_slot, _value, _boundary, path, _index), do: Schema.error(:slot_entry, path)

  defp content(
         :local,
         %{"owner" => owner, "caller" => caller, "id" => id} = value,
         %{kind: :local, root: root} = b,
         path
       )
       when map_size(value) == 3 do
    with true <- owner == root,
         {:ok, _} <- Schema.normalize(:opaque_id, caller, b, path),
         {:ok, _} <- Schema.normalize(:opaque_id, id, b, path) do
      {:ok, value}
    else
      _ -> Schema.error(:content_owner, path)
    end
  end

  defp content(:local, _value, _boundary, path), do: Schema.error(:content_owner, path)

  defp content(:host, value, boundary, path),
    do: Schema.normalize({:semantic, 1}, value, boundary, path)
end
