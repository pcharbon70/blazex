defmodule BlazeX.UITree.ComponentEvaluator do
  @moduledoc """
  Atomically accepts Core evaluations whose output is a valid semantic tree.
  """

  alias BlazeX.Core.{Diagnostic, Evaluation, Evaluator, Event, Identity}
  alias BlazeX.UITree.{Document, IntentSet, Node}

  @spec mount(module(), Identity.t(), map()) ::
          {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def mount(component, identity, props) do
    with {:ok, evaluation} <- Evaluator.mount(component, identity, props) do
      validate_output(evaluation, :mount)
    end
  end

  @spec update(Evaluation.t(), map()) :: {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def update(%Evaluation{} = evaluation, props) do
    with {:ok, candidate} <- Evaluator.update(evaluation, props) do
      validate_output(candidate, :update)
    end
  end

  def update(value, props), do: Evaluator.update(value, props)

  @spec dispatch(Evaluation.t(), Event.t()) ::
          {:ok, Evaluation.t(), [term()]} | {:error, Diagnostic.t()}
  def dispatch(%Evaluation{} = evaluation, %Event{} = event) do
    with :ok <- validate_binding(evaluation.output, event, evaluation.component),
         {:ok, candidate, emissions} <- Evaluator.dispatch(evaluation, event),
         {:ok, accepted} <- validate_output(candidate, :event) do
      {:ok, accepted, emissions}
    end
  end

  def dispatch(evaluation, event), do: Evaluator.dispatch(evaluation, event)

  @spec replace(Evaluation.t(), map()) :: {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def replace(%Evaluation{} = evaluation, props) do
    with {:ok, candidate} <- Evaluator.replace(evaluation, props) do
      validate_output(candidate, :replace)
    end
  end

  def replace(value, props), do: Evaluator.replace(value, props)

  defp validate_output(%Evaluation{output: %Node{} = output} = evaluation, stage) do
    case Node.validate(output) do
      :ok when output.identity == evaluation.identity ->
        {:ok, evaluation}

      :ok ->
        diagnostic(:root_identity_mismatch, stage, evaluation.component)

      {:error, error} ->
        diagnostic(:invalid_semantic_output, stage, evaluation.component, error.code)
    end
  end

  defp validate_output(%Evaluation{output: %Document{} = output} = evaluation, stage) do
    case Document.validate(output) do
      :ok when output.root.identity == evaluation.identity ->
        {:ok, evaluation}

      :ok ->
        diagnostic(:root_identity_mismatch, stage, evaluation.component)

      {:error, reason} ->
        diagnostic(:invalid_semantic_output, stage, evaluation.component, reason)
    end
  end

  defp validate_output(%Evaluation{output: %IntentSet{} = output} = evaluation, stage) do
    case IntentSet.validate(output) do
      :ok when output.document.root.identity == evaluation.identity ->
        {:ok, evaluation}

      :ok ->
        diagnostic(:root_identity_mismatch, stage, evaluation.component)

      {:error, reason} ->
        diagnostic(:invalid_semantic_output, stage, evaluation.component, reason)
    end
  end

  defp validate_output(%Evaluation{} = evaluation, stage),
    do: diagnostic(:invalid_semantic_output, stage, evaluation.component, :malformed_node)

  defp validate_binding(%Document{} = document, event, component) do
    case Document.resolve(document, event) do
      {:ok, _binding} -> :ok
      {:error, reason} -> diagnostic(:unbound_event, :event, component, reason)
    end
  end

  defp validate_binding(%IntentSet{document: document}, event, component),
    do: validate_binding(document, event, component)

  defp validate_binding(_output, _event, component),
    do: diagnostic(:unbound_event, :event, component, :document_required)

  defp diagnostic(code, stage, component, detail \\ nil) do
    {:error, %Diagnostic{code: code, stage: stage, component: component, detail: detail}}
  end
end
