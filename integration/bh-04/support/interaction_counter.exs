defmodule BlazeX.BH04.InteractionCounter do
  @moduledoc false
  @behaviour BlazeX.Core.Component
  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.UITree.{Binding, Document, Node}
  def mode, do: :stateful
  def init(_, _), do: {:ok, 0}
  def update(_, state, _), do: {:ok, state}
  def handle_event(_, _, state, _), do: {:ok, state + 1, []}
  def render(props, state, context) do
    state = if Map.get(props, :quiet, false), do: 0, else: state
    {:ok, label_id} = Identity.child(context.identity, :label)
    {:ok, label} = Node.text(label_id, "Events: #{state}", key: :label)
    controls = Enum.map(Event.names(), fn event ->
      {:ok, id} = Identity.child(context.identity, event)
      {:ok, node} = Node.new(if(event in [:change, :select], do: :field, else: :action), id, key: event)
      node
    end)
    {:ok, root} = Node.container(:group, context.identity, [label | controls])
    bindings = Enum.map(Event.names(), fn event ->
      {:ok, id} = Identity.child(context.identity, event)
      {:ok, binding} = Binding.new(event, context.identity, id)
      binding
    end)
    Document.new(root, bindings)
  end
end
