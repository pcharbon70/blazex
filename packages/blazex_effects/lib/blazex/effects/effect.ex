defmodule BlazeX.Effects.Effect do
  @moduledoc """
  Provider-neutral version-1 effect request.
  """

  alias BlazeX.Core.{Identity, Portable}
  alias BlazeX.Effects.Capability

  @version 1
  @max_timeout 86_400_000

  @enforce_keys [:version, :id, :owner, :capability, :operation, :payload, :timeout_ms, :fallback]
  defstruct [:version, :id, :owner, :capability, :operation, :payload, :timeout_ms, :fallback]

  @type t :: %__MODULE__{
          version: 1,
          id: Identity.portable_key(),
          owner: Identity.t(),
          capability: Capability.name(),
          operation: atom(),
          payload: map(),
          timeout_ms: pos_integer() | nil,
          fallback: Capability.fallback()
        }

  @spec new(Identity.portable_key(), Identity.t(), Capability.name(), atom(), map(), keyword()) ::
          {:ok, t()} | {:error, atom()}
  def new(id, owner, capability, operation, payload \\ %{}, options \\ []) do
    timeout_ms =
      if Keyword.keyword?(options), do: Keyword.get(options, :timeout_ms), else: :invalid

    fallback =
      if Keyword.keyword?(options), do: Keyword.get(options, :fallback, :fail), else: :invalid

    cond do
      not Identity.portable_key?(id) ->
        {:error, :invalid_effect_id}

      not Identity.valid?(owner) ->
        {:error, :invalid_owner}

      not Capability.name?(capability) ->
        {:error, :unknown_capability}

      not Capability.operation?(capability, operation) ->
        {:error, :invalid_operation}

      not is_map(payload) or not Portable.valid?(payload) ->
        {:error, :invalid_payload}

      not valid_timeout?(timeout_ms) ->
        {:error, :invalid_timeout}

      fallback not in [:fail, :omit, :component] ->
        {:error, :invalid_fallback}

      true ->
        {:ok,
         %__MODULE__{
           version: @version,
           id: id,
           owner: owner,
           capability: capability,
           operation: operation,
           payload: payload,
           timeout_ms: timeout_ms,
           fallback: fallback
         }}
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = effect) do
    effect.version == @version and
      match?(
        {:ok, %__MODULE__{}},
        new(effect.id, effect.owner, effect.capability, effect.operation, effect.payload,
          timeout_ms: effect.timeout_ms,
          fallback: effect.fallback
        )
      )
  end

  def valid?(_effect), do: false

  defp valid_timeout?(nil), do: true
  defp valid_timeout?(timeout), do: is_integer(timeout) and timeout in 1..@max_timeout
end
