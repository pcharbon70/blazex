defmodule BlazeX.Effects.Provider do
  @moduledoc """
  Behaviour implemented only by outward concrete capability providers.

  The contract passes effect data and result data; it never exposes a provider
  object to portable component state.
  """

  alias BlazeX.Effects.{Capability, Effect, Result}

  @callback capabilities() :: [Capability.name()]
  @callback request(Effect.t()) :: {:ok, Result.t()} | {:error, term()}
  @callback cancel(Effect.t()) :: :ok | {:error, term()}
  @callback dispose(BlazeX.Effects.Resource.t()) :: :ok | {:error, term()}
end
