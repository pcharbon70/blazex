defmodule BlazeX.Effects.Result do
  @moduledoc """
  Terminal provider-neutral effect outcome.
  """

  alias BlazeX.Core.{Identity, Portable}
  alias BlazeX.Effects.Resource

  @statuses [:ok, :denied, :cancelled, :timeout, :unsupported, :failed]

  @enforce_keys [:effect_id, :owner, :status, :value]
  defstruct [:effect_id, :owner, :status, :value]

  @type status :: :ok | :denied | :cancelled | :timeout | :unsupported | :failed
  @type t :: %__MODULE__{
          effect_id: Identity.portable_key(),
          owner: Identity.t(),
          status: status(),
          value: term() | nil
        }

  @spec statuses() :: [status()]
  def statuses, do: @statuses

  @spec new(Identity.portable_key(), Identity.t(), status(), term() | nil) ::
          {:ok, t()} | {:error, atom()}
  def new(effect_id, owner, status, value \\ nil) do
    cond do
      not Identity.portable_key?(effect_id) -> {:error, :invalid_effect_id}
      not Identity.valid?(owner) -> {:error, :invalid_owner}
      status not in @statuses -> {:error, :invalid_status}
      status != :ok and not is_nil(value) -> {:error, :unexpected_result_value}
      status == :ok and not valid_value?(value) -> {:error, :invalid_result_value}
      true -> {:ok, %__MODULE__{effect_id: effect_id, owner: owner, status: status, value: value}}
    end
  end

  defp valid_value?(%Resource{} = resource), do: Resource.valid?(resource)
  defp valid_value?(value), do: Portable.valid?(value)
end
