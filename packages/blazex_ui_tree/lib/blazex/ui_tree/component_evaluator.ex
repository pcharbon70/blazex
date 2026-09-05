defmodule BlazeX.UITree.ComponentEvaluator do
  @moduledoc """
  Atomically accepts Core evaluations whose output is a valid semantic tree.
  """

  alias BlazeX.Core.{Diagnostic, Evaluation, Evaluator, Identity}
  alias BlazeX.UITree.Node

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

  @spec replace(Evaluation.t(), map()) :: {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def replace(%Evaluation{} = evaluation, props) do
    with {:ok, candidate} <- Evaluator.replace(evaluation, props) do
      validate_output(candidate, :replace)
    end
  end

  def replace(value, props), do: Evaluator.replace(value, props)

  defp validate_output(%Evaluation{output: output} = evaluation, stage) do
    case Node.validate(output) do
      :ok when output.identity == evaluation.identity ->
        {:ok, evaluation}

      :ok ->
        diagnostic(:root_identity_mismatch, stage, evaluation.component)

      {:error, error} ->
        diagnostic(:invalid_semantic_output, stage, evaluation.component, error.code)
    end
  end

  defp diagnostic(code, stage, component, detail \\ nil) do
    {:error, %Diagnostic{code: code, stage: stage, component: component, detail: detail}}
  end
end
