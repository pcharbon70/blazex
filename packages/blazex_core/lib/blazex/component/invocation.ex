defmodule BlazeX.Component.Invocation do
  @moduledoc "Atomic prop/slot normalization and immutable update. Does not evaluate components."
  alias BlazeX.Component.{Props, Schema, Slots}

  def normalize(schema, props, slots, boundary) do
    with true <- Keyword.keyword?(schema) and Keyword.keys(schema) == [:props, :slots],
         true <- Schema.boundary?(boundary),
         {:ok, normalized_props} <- Props.normalize(schema[:props], props, boundary),
         {:ok, normalized_slots} <- Slots.normalize(schema[:slots], slots, boundary) do
      {:ok,
       %{
         contract: Schema.version(),
         root: boundary.root,
         boundary: boundary.kind,
         schema: schema,
         props: normalized_props,
         slots: normalized_slots
       }}
    else
      false -> Schema.error(:invalid_invocation, [])
      error -> error
    end
  end

  def update(previous, schema, props, slots, boundary) do
    valid =
      is_map(previous) and not is_struct(previous) and
        Map.get(previous, :contract) == Schema.version() and Map.get(previous, :schema) == schema and
        Schema.boundary?(boundary) and Map.get(previous, :root) == boundary.root and
        Map.get(previous, :boundary) == boundary.kind

    result =
      if valid,
        do: normalize(schema, props, slots, boundary),
        else: Schema.error(:invalid_prior, [])

    case result do
      {:ok, invocation} -> {:ok, invocation}
      {:error, diagnostic} -> {:error, diagnostic, previous}
    end
  end
end
