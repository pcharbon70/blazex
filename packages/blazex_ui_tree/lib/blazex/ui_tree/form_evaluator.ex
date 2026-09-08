defmodule BlazeX.UITree.FormEvaluator do
  @moduledoc "Validates additive form output around the existing component callback algebra."
  alias BlazeX.Core.Evaluator
  alias BlazeX.UITree.{Document, FormOutput}

  def mount(component, identity, props) do
    with {:ok, evaluation} <- Evaluator.mount(component, identity, props), do: accept(evaluation)
  end

  def update(evaluation, props) do
    with {:ok, candidate} <- Evaluator.update(evaluation, props), do: accept(candidate)
  end

  def dispatch(evaluation, event), do: dispatch(evaluation, event, &(&1 == []))

  # Outward adapters validate typed emissions; UI-tree does not depend on providers.
  def dispatch(evaluation, event, validate_emissions) when is_function(validate_emissions, 1) do
    with {:ok, _} <- Document.resolve(evaluation.output.intent.document, event),
         true <- allowed?(evaluation.output.forms, event),
         {:ok, candidate, emissions} <- Evaluator.dispatch(evaluation, event),
         true <- validate_emissions.(emissions),
         {:ok, candidate} <- accept(candidate) do
      {:ok, candidate, emissions}
    else
      _ -> {:error, :invalid_form_event}
    end
  end

  defp allowed?(forms, event) do
    form =
      Enum.find(
        forms,
        &(&1.owner == event.source or Enum.any?(&1.choices, fn c -> c.owner == event.source end))
      )

    cond do
      form == nil ->
        event.name not in [:change, :select]

      form.disabled or form.readonly ->
        false

      event.name not in [:change, :select] ->
        true

      form.kind == :text ->
        is_binary(event.payload["value"]) and byte_size(event.payload["value"]) <= 2048

      form.kind == :check ->
        is_boolean(event.payload["checked"])

      true ->
        Enum.any?(
          form.choices,
          &(&1.owner == event.source and &1.value == event.payload["value"])
        ) and is_boolean(event.payload["checked"])
    end
  end

  defp accept(evaluation) do
    with :ok <- FormOutput.validate(evaluation.output),
         true <- evaluation.output.intent.document.root.identity == evaluation.identity,
         true <-
           Enum.all?(
             evaluation.output.forms,
             &(&1.edit_sequence <= evaluation.last_event_sequence)
           ) do
      {:ok, evaluation}
    else
      _ -> {:error, :invalid_form_output}
    end
  end
end
