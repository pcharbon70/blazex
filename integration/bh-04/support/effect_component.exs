defmodule BlazeX.BH04.EffectComponent do
  alias BlazeX.Core.Identity
  alias BlazeX.Effects.Effect
  alias BlazeX.UITree.{Node, Document, Binding, IntentSet, FormOutput, FormState, Focus}
  def mode, do: :stateful
  def init(_, _), do: {:ok, %{count: 0, value: "initial", sequence: 0}}
  def update(_, state, _), do: {:ok, state}

  def handle_event(event, props, state, _) do
    {:ok, effect} =
      Effect.new(
        "tick-#{event.sequence}",
        event.owner,
        :time,
        :schedule,
        %{"delay_ms" => Map.get(props, "delay_ms", 1)},
        timeout_ms: Map.get(props, "timeout_ms", 100),
        fallback:
          Map.fetch!(
            %{"fail" => :fail, "omit" => :omit, "component" => :component},
            Map.get(props, "fallback", "fail")
          )
      )

    next = %{
      state
      | count: state.count + 1,
        value: Map.get(event.payload, "value", state.value),
        sequence: event.sequence
    }

    {:ok, next, [effect]}
  end

  def render(props, state, context) do
    key = if props["replace"], do: :replacement, else: :field
    {:ok, field_id} = Identity.child(context.identity, key)
    {:ok, field} = Node.new(:field, field_id, key: key)
    {:ok, action_id} = Identity.child(context.identity, :action)
    {:ok, action} = Node.new(:action, action_id, key: :action)
    {:ok, label_id} = Identity.child(context.identity, :label)
    {:ok, label} = Node.text(label_id, "Count #{state.count}", key: :label)
    children = if props["reverse"], do: [label, action, field], else: [field, action, label]
    {:ok, root} = Node.container(:group, context.identity, children)
    {:ok, change} = Binding.new(:change, context.identity, field_id)
    {:ok, activate} = Binding.new(:activate, context.identity, action_id)
    {:ok, doc} = Document.new(root, [change, activate])
    {:ok, focus} = Focus.new(field_id, :target, order: 0, auto_focus: true)
    {:ok, intent} = IntentSet.new(doc, focus: [focus])
    {:ok, form} = FormState.new(field_id, :text, state.value, edit_sequence: state.sequence)
    FormOutput.new(intent, [form])
  end
end
