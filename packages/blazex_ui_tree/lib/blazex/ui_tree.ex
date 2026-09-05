defmodule BlazeX.UITree do
  @moduledoc """
  Experimental version-1 semantic UI tree.

  Phase 2 owns a bounded node vocabulary, deterministic validation, and
  traversal. Phase 3 adds semantic event bindings and atomic dispatch. Phase 4
  adds portable token, layout, accessibility, focus, and selection intent.
  Renderer behavior, geometry, platform mappings, extensions, and patches
  remain deferred to later phases.
  """

  alias BlazeX.Core.{Diagnostic, Evaluation, Identity}
  alias BlazeX.UITree.{ComponentEvaluator, Node, ValidationError}

  @spec validate(term()) :: :ok | {:error, ValidationError.t()}
  def validate(root), do: Node.validate(root)

  @spec preorder(term()) :: {:ok, [Node.t()]} | {:error, ValidationError.t()}
  def preorder(root), do: Node.preorder(root)

  @spec mount_component(module(), Identity.t(), map()) ::
          {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def mount_component(component, identity, props),
    do: ComponentEvaluator.mount(component, identity, props)

  @spec update_component(Evaluation.t(), map()) ::
          {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def update_component(evaluation, props), do: ComponentEvaluator.update(evaluation, props)

  @spec replace_component(Evaluation.t(), map()) ::
          {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def replace_component(evaluation, props), do: ComponentEvaluator.replace(evaluation, props)

  @spec dispatch_component(Evaluation.t(), BlazeX.Core.Event.t()) ::
          {:ok, Evaluation.t(), [term()]} | {:error, Diagnostic.t()}
  def dispatch_component(evaluation, event), do: ComponentEvaluator.dispatch(evaluation, event)
end
