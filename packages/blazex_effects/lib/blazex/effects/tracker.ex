defmodule BlazeX.Effects.Tracker do
  @moduledoc """
  Pure deterministic pending-effect and opaque-resource lifecycle tracker.
  """

  alias BlazeX.Core.Identity
  alias BlazeX.Effects.{Capability, Effect, Error, Resource, Result}

  @enforce_keys [:grants, :pending, :seen_effect_ids, :resources]
  defstruct [:grants, :pending, :seen_effect_ids, :resources]

  @type resource_state :: :active | :cancelled | :disposed
  @type t :: %__MODULE__{
          grants: MapSet.t(Capability.name()),
          pending: %{optional(Identity.portable_key()) => Effect.t()},
          seen_effect_ids: MapSet.t(Identity.portable_key()),
          resources: %{optional(Resource.t()) => resource_state()}
        }

  @spec new([Capability.name()]) :: {:ok, t()} | {:error, Error.t()}
  def new(grants \\ [])

  def new(grants) when is_list(grants) do
    cond do
      not proper_list?(grants) ->
        error(:invalid_grants, :initialize)

      not Enum.all?(grants, &Capability.name?/1) ->
        error(:unknown_grant, :initialize)

      length(grants) != MapSet.size(MapSet.new(grants)) ->
        error(:duplicate_grant, :initialize)

      true ->
        {:ok,
         %__MODULE__{
           grants: MapSet.new(grants),
           pending: %{},
           seen_effect_ids: MapSet.new(),
           resources: %{}
         }}
    end
  end

  def new(_grants), do: error(:invalid_grants, :initialize)

  @spec submit(t(), Effect.t()) ::
          {:ok, t(), :pending | Result.t()} | {:error, Error.t()}
  def submit(%__MODULE__{} = tracker, %Effect{} = effect) do
    cond do
      not valid?(tracker) ->
        error(:invalid_tracker, :submit)

      not Effect.valid?(effect) ->
        error(:invalid_effect, :submit)

      MapSet.member?(tracker.seen_effect_ids, effect.id) ->
        error(:duplicate_effect_id, :submit)

      not MapSet.member?(tracker.grants, effect.capability) ->
        {:ok, mark_seen(tracker, effect.id), result!(effect, :denied)}

      true ->
        {:ok,
         %{
           tracker
           | pending: Map.put(tracker.pending, effect.id, effect),
             seen_effect_ids: MapSet.put(tracker.seen_effect_ids, effect.id)
         }, :pending}
    end
  end

  def submit(_tracker, _effect), do: error(:invalid_submission, :submit)

  @spec complete(t(), Identity.portable_key(), term()) ::
          {:ok, t(), Result.t()} | {:error, Error.t()}
  def complete(%__MODULE__{} = tracker, effect_id, value) do
    with :ok <- validate_tracker(tracker, :complete),
         {:ok, effect} <- pending_effect(tracker, effect_id, :complete),
         {:ok, result} <- result(effect, :ok, value) do
      {:ok, remove_pending(tracker, effect_id), result}
    end
  end

  @spec complete_resource(t(), Identity.portable_key(), Identity.portable_key()) ::
          {:ok, t(), Result.t(), Resource.t()} | {:error, Error.t()}
  def complete_resource(%__MODULE__{} = tracker, effect_id, resource_id) do
    with :ok <- validate_tracker(tracker, :complete),
         {:ok, effect} <- pending_effect(tracker, effect_id, :complete),
         {:ok, resource} <- resource(effect.owner, effect.capability, resource_id),
         :ok <- ensure_resource_absent(tracker, resource, :complete),
         {:ok, result} <- result(effect, :ok, resource) do
      updated = %{
        tracker
        | pending: Map.delete(tracker.pending, effect_id),
          resources: Map.put(tracker.resources, resource, :active)
      }

      {:ok, updated, result, resource}
    else
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  @spec cancel(t(), Identity.portable_key()) :: {:ok, t(), Result.t()} | {:error, Error.t()}
  def cancel(tracker, effect_id), do: terminal(tracker, effect_id, :cancelled, :cancel)

  @spec timeout(t(), Identity.portable_key()) :: {:ok, t(), Result.t()} | {:error, Error.t()}
  def timeout(tracker, effect_id), do: terminal(tracker, effect_id, :timeout, :timeout)

  @spec fail(t(), Identity.portable_key()) :: {:ok, t(), Result.t()} | {:error, Error.t()}
  def fail(tracker, effect_id), do: terminal(tracker, effect_id, :failed, :fail)

  @spec transfer(t(), Resource.t(), Identity.t()) ::
          {:ok, t(), Resource.t()} | {:error, Error.t()}
  def transfer(%__MODULE__{} = tracker, %Resource{} = resource, %Identity{} = new_owner) do
    with :ok <- validate_tracker(tracker, :transfer),
         :active <- Map.get(tracker.resources, resource, :missing),
         :ok <- validate_transfer_owner(new_owner, resource),
         {:ok, transferred} <- resource(new_owner, resource.capability, resource.id),
         :ok <- ensure_resource_absent(tracker, transferred, :transfer) do
      resources =
        tracker.resources
        |> Map.delete(resource)
        |> Map.put(transferred, :active)

      {:ok, %{tracker | resources: resources}, transferred}
    else
      :missing -> error(:resource_not_found, :transfer)
      :cancelled -> error(:resource_not_active, :transfer)
      :disposed -> error(:resource_not_active, :transfer)
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  def transfer(_tracker, _resource, _owner), do: error(:invalid_transfer, :transfer)

  @spec cancel_resource(t(), Resource.t()) :: {:ok, t()} | {:error, Error.t()}
  def cancel_resource(%__MODULE__{} = tracker, %Resource{} = resource) do
    with :ok <- validate_tracker(tracker, :cancel_resource) do
      set_resource_state(tracker, resource, :cancelled, :cancel_resource)
    end
  end

  @spec dispose(t(), Resource.t()) :: {:ok, t()} | {:error, Error.t()}
  def dispose(%__MODULE__{} = tracker, %Resource{} = resource) do
    with :ok <- validate_tracker(tracker, :dispose) do
      case Map.get(tracker.resources, resource, :missing) do
        :missing -> error(:resource_not_found, :dispose)
        :disposed -> {:ok, tracker}
        _state -> {:ok, %{tracker | resources: Map.put(tracker.resources, resource, :disposed)}}
      end
    end
  end

  def dispose(_tracker, _resource), do: error(:invalid_resource, :dispose)

  @spec dispose_owner(t(), Identity.t()) :: {:ok, t(), [Result.t()]} | {:error, Error.t()}
  def dispose_owner(%__MODULE__{} = tracker, %Identity{} = owner) do
    cond do
      not valid?(tracker) ->
        error(:invalid_tracker, :dispose_owner)

      Identity.valid?(owner) ->
        {owned_pending, retained_pending} =
          Enum.split_with(tracker.pending, fn {_id, effect} -> effect.owner == owner end)

        results = Enum.map(owned_pending, fn {_id, effect} -> result!(effect, :cancelled) end)

        resources =
          Map.new(tracker.resources, fn
            {%Resource{owner: ^owner} = resource, _state} -> {resource, :disposed}
            pair -> pair
          end)

        {:ok, %{tracker | pending: Map.new(retained_pending), resources: resources}, results}

      true ->
        error(:invalid_owner, :dispose_owner)
    end
  end

  def dispose_owner(_tracker, _owner), do: error(:invalid_owner, :dispose_owner)

  @spec resource_state(t(), Resource.t()) :: {:ok, resource_state()} | {:error, Error.t()}
  def resource_state(%__MODULE__{} = tracker, %Resource{} = resource) do
    with :ok <- validate_tracker(tracker, :inspect) do
      case Map.fetch(tracker.resources, resource) do
        {:ok, state} -> {:ok, state}
        :error -> error(:resource_not_found, :inspect)
      end
    end
  end

  def resource_state(_tracker, _resource), do: error(:invalid_resource, :inspect)

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = tracker) do
    match?(%MapSet{}, tracker.grants) and is_map(tracker.pending) and
      match?(%MapSet{}, tracker.seen_effect_ids) and is_map(tracker.resources) and
      Enum.all?(tracker.grants, &Capability.name?/1) and
      Enum.all?(tracker.pending, fn
        {id, %Effect{} = effect} -> id == effect.id and Effect.valid?(effect)
        _other -> false
      end) and
      Enum.all?(tracker.resources, fn {resource, state} ->
        Resource.valid?(resource) and state in [:active, :cancelled, :disposed]
      end)
  end

  def valid?(_tracker), do: false

  defp terminal(%__MODULE__{} = tracker, effect_id, status, stage) do
    with :ok <- validate_tracker(tracker, stage),
         {:ok, effect} <- pending_effect(tracker, effect_id, stage) do
      {:ok, remove_pending(tracker, effect_id), result!(effect, status)}
    end
  end

  defp terminal(_tracker, _effect_id, _status, stage), do: error(:invalid_tracker, stage)

  defp pending_effect(tracker, effect_id, stage) do
    case Map.fetch(tracker.pending, effect_id) do
      {:ok, effect} -> {:ok, effect}
      :error -> error(:effect_not_pending, stage)
    end
  end

  defp set_resource_state(tracker, resource, state, stage) do
    case Map.get(tracker.resources, resource, :missing) do
      :missing -> error(:resource_not_found, stage)
      :disposed -> error(:resource_not_active, stage)
      _current -> {:ok, %{tracker | resources: Map.put(tracker.resources, resource, state)}}
    end
  end

  defp validate_transfer_owner(owner, resource) do
    cond do
      not Identity.valid?(owner) -> error(:invalid_owner, :transfer)
      owner.generation != resource.generation -> error(:generation_mismatch, :transfer)
      true -> :ok
    end
  end

  defp ensure_resource_absent(tracker, resource, stage) do
    if Map.has_key?(tracker.resources, resource),
      do: error(:duplicate_resource, stage),
      else: :ok
  end

  defp validate_tracker(tracker, stage) do
    if valid?(tracker), do: :ok, else: error(:invalid_tracker, stage)
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false

  defp remove_pending(tracker, effect_id),
    do: %{tracker | pending: Map.delete(tracker.pending, effect_id)}

  defp mark_seen(tracker, effect_id),
    do: %{tracker | seen_effect_ids: MapSet.put(tracker.seen_effect_ids, effect_id)}

  defp resource(owner, capability, resource_id) do
    case Resource.new(owner, capability, resource_id) do
      {:ok, resource} -> {:ok, resource}
      {:error, reason} -> error(reason, :resource)
    end
  end

  defp result(effect, status, value) do
    case Result.new(effect.id, effect.owner, status, value) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> error(reason, :result)
    end
  end

  defp result!(effect, status) do
    {:ok, result} = Result.new(effect.id, effect.owner, status)
    result
  end

  defp error(code, stage, detail \\ nil),
    do: {:error, %Error{code: code, stage: stage, detail: detail}}
end
