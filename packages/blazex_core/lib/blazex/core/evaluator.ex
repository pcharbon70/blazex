defmodule BlazeX.Core.Evaluator do
  @moduledoc """
  Deterministic evaluator for experimental pure and stateful components.

  Core intentionally treats render output as opaque. The UI-tree package owns
  semantic output validation and accepts an evaluation only after the complete
  tree passes.
  """

  alias BlazeX.Core.{Context, Diagnostic, Evaluation, Identity, Portable}

  @spec mount(module(), Identity.t(), map()) :: {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def mount(component, identity, props), do: do_mount(component, identity, props, :mount)

  @spec update(Evaluation.t(), map()) :: {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def update(%Evaluation{} = evaluation, props) do
    with :ok <- validate_evaluation(evaluation, :update),
         :ok <- validate_props(props, evaluation.component, :update) do
      revision = evaluation.revision + 1
      context = context(evaluation.identity, revision, :update)

      case evaluation.mode do
        :pure ->
          with {:ok, output} <- callback(evaluation.component, :render, [props, context], :render) do
            {:ok, %{evaluation | props: props, output: output, revision: revision}}
          end

        :stateful ->
          with {:ok, state} <-
                 callback(
                   evaluation.component,
                   :update,
                   [props, evaluation.state, context],
                   :update
                 ),
               :ok <- validate_state(state, evaluation.component, :update),
               {:ok, output} <-
                 callback(evaluation.component, :render, [props, state, context], :render) do
            {:ok, %{evaluation | props: props, state: state, output: output, revision: revision}}
          end
      end
    end
  end

  def update(value, _props), do: diagnostic(:invalid_evaluation, :update, component_of(value))

  @spec replace(Evaluation.t(), map()) :: {:ok, Evaluation.t()} | {:error, Diagnostic.t()}
  def replace(%Evaluation{} = evaluation, props) do
    with :ok <- validate_evaluation(evaluation, :replace),
         {:ok, replacement_identity} <- replace_identity(evaluation) do
      do_mount(evaluation.component, replacement_identity, props, :replace)
    end
  end

  def replace(value, _props), do: diagnostic(:invalid_evaluation, :replace, component_of(value))

  defp do_mount(component, identity, props, transition) do
    stage = if transition == :replace, do: :replace, else: :mount

    with :ok <- validate_component(component, stage),
         :ok <- validate_identity(identity, component, stage),
         :ok <- validate_props(props, component, stage),
         {:ok, mode} <- component_mode(component, stage) do
      context = context(identity, 0, transition)

      case mode do
        :pure -> mount_pure(component, identity, props, context)
        :stateful -> mount_stateful(component, identity, props, context)
      end
    end
  end

  defp mount_pure(component, identity, props, context) do
    with {:ok, output} <- callback(component, :render, [props, context], :render) do
      {:ok,
       %Evaluation{
         component: component,
         mode: :pure,
         identity: identity,
         props: props,
         state: nil,
         output: output,
         revision: 0
       }}
    end
  end

  defp mount_stateful(component, identity, props, context) do
    with {:ok, state} <- callback(component, :init, [props, context], :init),
         :ok <- validate_state(state, component, :init),
         {:ok, output} <- callback(component, :render, [props, state, context], :render) do
      {:ok,
       %Evaluation{
         component: component,
         mode: :stateful,
         identity: identity,
         props: props,
         state: state,
         output: output,
         revision: 0
       }}
    end
  end

  defp validate_component(component, _stage) when is_atom(component) do
    if Code.ensure_loaded?(component),
      do: :ok,
      else: diagnostic(:invalid_component, :contract, component)
  end

  defp validate_component(_component, _stage), do: diagnostic(:invalid_component, :contract, nil)

  defp component_mode(component, stage) do
    if function_exported?(component, :mode, 0) do
      case invoke(component, :mode, [], stage) do
        {:ok, mode} when mode in [:pure, :stateful] -> {:ok, mode}
        {:ok, _other} -> diagnostic(:invalid_mode, :contract, component)
        {:error, diagnostic} -> {:error, diagnostic}
      end
    else
      diagnostic(:missing_callback, :contract, component, :mode)
    end
  end

  defp callback(component, callback, arguments, stage) do
    if function_exported?(component, callback, length(arguments)) do
      case invoke(component, callback, arguments, stage) do
        {:ok, {:ok, value}} -> {:ok, value}
        {:ok, {:error, _reason}} -> diagnostic(:callback_rejected, stage, component, callback)
        {:ok, _other} -> diagnostic(:invalid_callback_result, stage, component, callback)
        {:error, diagnostic} -> {:error, diagnostic}
      end
    else
      diagnostic(:missing_callback, stage, component, callback)
    end
  end

  defp invoke(component, callback, arguments, stage) do
    try do
      {:ok, apply(component, callback, arguments)}
    rescue
      _exception -> diagnostic(:callback_failed, stage, component, callback)
    catch
      _kind, _value -> diagnostic(:callback_failed, stage, component, callback)
    end
  end

  defp validate_evaluation(%Evaluation{} = evaluation, stage) do
    valid =
      is_atom(evaluation.component) and evaluation.mode in [:pure, :stateful] and
        Identity.valid?(evaluation.identity) and is_map(evaluation.props) and
        Portable.valid?(evaluation.props) and is_integer(evaluation.revision) and
        evaluation.revision >= 0 and
        (evaluation.mode == :pure or Portable.valid?(evaluation.state))

    if valid,
      do: :ok,
      else: diagnostic(:invalid_evaluation, stage, evaluation.component)
  end

  defp validate_identity(identity, component, stage) do
    if Identity.valid?(identity),
      do: :ok,
      else: diagnostic(:invalid_identity, stage, component)
  end

  defp validate_props(props, component, stage) do
    if is_map(props) and Portable.valid?(props),
      do: :ok,
      else: diagnostic(:invalid_props, stage, component)
  end

  defp validate_state(state, component, stage) do
    if Portable.valid?(state),
      do: :ok,
      else: diagnostic(:invalid_state, stage, component)
  end

  defp replace_identity(%Evaluation{identity: identity, component: component}) do
    case Identity.replace(identity) do
      {:ok, replacement} -> {:ok, replacement}
      {:error, :generation_exhausted} -> diagnostic(:generation_exhausted, :replace, component)
      {:error, _reason} -> diagnostic(:invalid_identity, :replace, component)
    end
  end

  defp context(identity, revision, transition) do
    %Context{identity: identity, revision: revision, transition: transition}
  end

  defp component_of(%Evaluation{component: component}), do: component
  defp component_of(_value), do: nil

  defp diagnostic(code, stage, component, detail \\ nil) do
    {:error, %Diagnostic{code: code, stage: stage, component: component, detail: detail}}
  end
end
