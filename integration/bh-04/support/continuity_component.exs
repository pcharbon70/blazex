defmodule BlazeX.BH04.ContinuityComponent do
  @behaviour BlazeX.Core.Component
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Node, Document, Binding, IntentSet, FormState, FormOutput, Accessibility, Focus, Selection}
  def mode, do: :stateful
  def init(_, _), do: {:ok, %{value: "initial", checked: false, selected: ["alpha"], single: "alpha", sequence: 0, count: 0}}
  def update(_, state, _), do: {:ok, state}
  def handle_event(event, _, state, _) do
    key = List.last(event.source.path)
    next = cond do
      key in [:field, :replacement] -> %{state | value: event.payload["value"]}
      key == :check -> %{state | checked: event.payload["checked"]}
      key in [:alpha, :beta] -> %{state | selected: if(event.payload["checked"], do: Enum.uniq(state.selected ++ [event.payload["value"]]), else: List.delete(state.selected, event.payload["value"]))}
      key in [:single_alpha, :single_beta] -> %{state | single: if(event.payload["checked"], do: event.payload["value"], else: nil)}
      true -> state
    end
    {:ok, %{next | sequence: event.sequence, count: state.count + 1}, []}
  end
  def render(props, state, context) do
    owner = context.identity
    id = fn key -> {:ok, value} = Identity.child(owner, key); value end
    field_key = if props["replace"], do: :replacement, else: :field
    field_id = id.(field_key)
    {:ok, field} = Node.new(:field, field_id, key: field_key)
    {:ok, check} = Node.new(:field, id.(:check), key: :check)
    {:ok, action} = Node.new(:action, id.(:action), key: :action)
    {:ok, label} = Node.text(id.(:label), "Events: #{state.count}", key: :label)
    {multiple, choices} = collection(id.(:multiple), [:alpha, :beta], props["reverse"])
    {single, single_choices} = collection(id.(:single), [:single_alpha, :single_beta], props["reverse"])
    children = if props["remove"], do: [check, multiple, single, action, label], else: [field, check, multiple, single, action, label]
    children = if props["reverse"], do: Enum.reverse(children), else: children
    {:ok, root} = Node.container(:group, owner, children)
    forms = [form(id.(:check), :check, state.checked, state.sequence, indeterminate: props["mixed"] || false),
      form(id.(:multiple), :multiple, state.selected, state.sequence, choices: choices),
      form(id.(:single), :single, state.single, state.sequence, choices: single_choices)]
    forms = if props["remove"], do: forms, else: [form(field_id, :text, props["value"] || state.value, state.sequence, disabled: props["disabled"] || false, readonly: props["readonly"] || false, required: true, invalid: props["invalid"] || false) | forms]
    sources = [{:select, id.(:check)}, {:activate, id.(:action)}, {:submit, id.(:action)}] ++ Enum.map(choices ++ single_choices, &{:select, &1.owner})
    sources = if props["remove"], do: sources, else: [{:change, field_id} | sources]
    bindings = Enum.map(sources, fn {name, source} -> {:ok, b} = Binding.new(name, owner, source); b end)
    {:ok, doc} = Document.new(root, bindings)
    accessibility = Enum.map([id.(:check) | Enum.map(choices ++ single_choices, & &1.owner)], fn target -> {:ok, a} = Accessibility.new(target, :checkbox); a end)
    {:ok, scope} = Focus.new(owner, :scope, restore: :previous, wrap: props["wrap"] || false)
    targets = [{id.(:check), 1}, {id.(:action), 6}] ++ Enum.with_index(Enum.map(choices ++ single_choices, & &1.owner), 2)
    targets = if props["remove"], do: targets, else: [{field_id, 0} | targets]
    focus = Enum.map(targets, fn {target, order} -> {:ok, f} = Focus.new(target, :target, order: order, auto_focus: if(props["focus_action"], do: target == id.(:action), else: target == field_id)); f end)
    selections = if props["range"] && !props["remove"] do
      {:ok, s} = Selection.new(field_id, :text_range, %{anchor: props["range"]["anchor"], focus: props["range"]["focus"], direction: if(props["range"]["backward"], do: :backward, else: :forward)}); [s]
    else [] end
    {:ok, intent} = IntentSet.new(doc, accessibility: accessibility, focus: [scope | focus], selections: selections)
    FormOutput.new(intent, forms)
  end
  defp form(owner, kind, value, sequence, options) do
    {:ok, form} = FormState.new(owner, kind, value, [{:edit_sequence, sequence} | options]); form
  end
  defp collection(owner, keys, reverse) do
    pairs = Enum.zip(keys, ["alpha", "beta"])
    pairs = if reverse, do: Enum.reverse(pairs), else: pairs
    choices = Enum.map(pairs, fn {key, value} -> {:ok, id} = Identity.child(owner, key); %{value: value, owner: id} end)
    children = Enum.map(Enum.zip(pairs, choices), fn {{key, _}, choice} -> {:ok, n} = Node.new(:selection, choice.owner, key: key); n end)
    {:ok, root} = Node.container(:collection, owner, children, key: List.last(owner.path)); {root, choices}
  end
end
