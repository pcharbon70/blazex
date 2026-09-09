defmodule BlazeX.UITree.RecoveryEvaluator do
  @moduledoc "Bounded evaluator facade and callback-independent semantic failure fallback."
  alias BlazeX.Component.{NestedTable, RecoveryPort, RootPort}
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Accessibility, Binding, Document, Focus, IntentSet, Node}

  for {name, arity} <- [
        prepare: 2,
        prepare_scheduled: 2,
        admit: 2,
        admit_action: 2,
        cleanup: 2,
        cleanup_removed: 2,
        scope_ingress: 2
      ] do
    args = Macro.generate_arguments(arity, __MODULE__)

    def unquote(name)({port, timeout}, unquote_splicing(args)),
      do: RecoveryPort.call(port, unquote(name), [unquote_splicing(args)], timeout)
  end

  def scope_followups({{module, _} = port, timeout}, candidate) do
    if function_exported?(module, :scope_followups, 2),
      do: RecoveryPort.call(port, :scope_followups, [candidate], timeout),
      else: []
  end

  def fallback(_, correlation, failure) do
    {:ok, id} = Identity.new(correlation.root, correlation.generation)
    {:ok, text_id} = Identity.child(id, "failure-status")
    {:ok, text} = Node.text(text_id, "This component is unavailable.")
    action = if failure.retry_visible, do: "retry", else: "reload"
    label = if failure.retry_visible, do: "Try again", else: "Reload"
    {:ok, action_id} = Identity.child(id, action)
    {:ok, label_id} = Identity.child(action_id, "label")
    {:ok, label_node} = Node.text(label_id, label)
    {:ok, button} = Node.container(:action, action_id, [label_node])
    {:ok, binding} = Binding.new(:activate, id, action_id)
    {:ok, root} = Node.container(:group, id, [text, button])
    {:ok, document} = Document.new(root, [binding])

    {:ok, status} =
      Accessibility.new(id, :status, name: "Component unavailable", live: :assertive)

    {:ok, button_a11y} = Accessibility.new(action_id, :button, name: label)
    {:ok, focus} = Focus.new(action_id, :target, order: 0, auto_focus: true)
    {:ok, output} = IntentSet.new(document, accessibility: [status, button_a11y], focus: [focus])

    RootPort.candidate(
      correlation,
      %{components: [], failure: failure},
      NestedTable.digest(output),
      %{output: output, recovery_fallback: true}
    )
  end
end
