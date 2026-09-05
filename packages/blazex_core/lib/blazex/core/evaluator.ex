defmodule BlazeX.Core.Evaluator do
  @moduledoc """
  Deterministic evaluator for experimental pure and stateful components.

  Core intentionally treats render output as opaque. The UI-tree package owns
  semantic output validation and accepts an evaluation only after the complete
  tree passes.
  """

  alias BlazeX.Core.{Context, Diagnostic, Evaluation, Event, Identity, Portable}

  @max_emissions 256

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

  @spec dispatch(Evaluation.t(), Event.t()) ::
          {:ok, Evaluation.t(), [term()]} | {:error, Diagnostic.t()}
  def dispatch(%Evaluation{} = evaluation, %Event{} = event) do
    with :ok <- validate_evaluation(evaluation, :event),
         :ok <- validate_event(evaluation, event),
         :ok <- validate_stateful(evaluation),
         {:ok, state, emissions} <- event_callback(evaluation, event),
         :ok <- validate_state(state, evaluation.component, :event),
         :ok <- validate_emissions(emissions, evaluation.component),
         {:ok, output} <-
           callback(
             evaluation.component,
             :render,
             [
               evaluation.props,
               state,
               context(evaluation.identity, evaluation.revision + 1, :event)
             ],
             :render
           ) do
      {:ok,
       %{
         evaluation
         | state: state,
           output: output,
           revision: evaluation.revision + 1,
           last_event_sequence: event.sequence
       }, emissions}
    end
  end

  def dispatch(%Evaluation{} = evaluation, _event),
    do: diagnostic(:invalid_event, :event, evaluation.component)

  def dispatch(value, _event), do: diagnostic(:invalid_evaluation, :event, component_of(value))

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
         revision: 0,
         last_event_sequence: 0
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
         revision: 0,
         last_event_sequence: 0
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

  defp event_callback(evaluation, event) do
    component = evaluation.component
    revision = evaluation.revision + 1
    context = context(evaluation.identity, revision, :event)

    if function_exported?(component, :handle_event, 4) do
      case invoke(
             component,
             :handle_event,
             [event, evaluation.props, evaluation.state, context],
             :event
           ) do
        {:ok, {:ok, state, emissions}} ->
          {:ok, state, emissions}

        {:ok, {:error, _reason}} ->
          diagnostic(:callback_rejected, :event, component, :handle_event)

        {:ok, _other} ->
          diagnostic(:invalid_callback_result, :event, component, :handle_event)

        {:error, diagnostic} ->
          {:error, diagnostic}
      end
    else
      diagnostic(:missing_callback, :event, component, :handle_event)
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
    state_valid =
      case evaluation.mode do
        :pure -> is_nil(evaluation.state)
        :stateful -> Portable.valid?(evaluation.state)
        _other -> false
      end

    valid =
      is_atom(evaluation.component) and evaluation.mode in [:pure, :stateful] and
        Identity.valid?(evaluation.identity) and is_map(evaluation.props) and
        Portable.valid?(evaluation.props) and is_integer(evaluation.revision) and
        evaluation.revision >= 0 and is_integer(evaluation.last_event_sequence) and
        evaluation.last_event_sequence >= 0 and state_valid

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

  defp validate_event(evaluation, event) do
    cond do
      not Event.valid?(event) ->
        diagnostic(:invalid_event, :event, evaluation.component)

      event.owner == evaluation.identity and event.sequence > evaluation.last_event_sequence ->
        :ok

      same_instance_different_generation?(event.owner, evaluation.identity) ->
        diagnostic(:stale_event, :event, evaluation.component)

      event.owner != evaluation.identity ->
        diagnostic(:event_owner_mismatch, :event, evaluation.component)

      true ->
        diagnostic(:stale_event_sequence, :event, evaluation.component)
    end
  end

  defp validate_stateful(%Evaluation{mode: :stateful}), do: :ok

  defp validate_stateful(%Evaluation{component: component}),
    do: diagnostic(:event_requires_stateful, :event, component)

  defp validate_emissions(emissions, component) do
    case proper_list_size(emissions) do
      {:ok, size} when size <= @max_emissions -> :ok
      _other -> diagnostic(:invalid_emissions, :event, component)
    end
  end

  defp same_instance_different_generation?(left, right) do
    left.root == right.root and left.path == right.path and left.generation != right.generation
  end

  defp proper_list_size(term), do: proper_list_size(term, 0)
  defp proper_list_size([], size), do: {:ok, size}
  defp proper_list_size([_head | _tail], size) when size == @max_emissions, do: :too_large
  defp proper_list_size([_head | tail], size), do: proper_list_size(tail, size + 1)
  defp proper_list_size(_improper, _size), do: :improper

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
