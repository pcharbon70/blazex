defmodule BlazeX.Effects.Resource do
  @moduledoc """
  Opaque portable resource identifier scoped to one owner generation.
  """

  alias BlazeX.Core.Identity
  alias BlazeX.Effects.Capability

  @enforce_keys [:owner, :capability, :id, :generation]
  defstruct [:owner, :capability, :id, :generation]

  @type t :: %__MODULE__{
          owner: Identity.t(),
          capability: Capability.name(),
          id: Identity.portable_key(),
          generation: pos_integer()
        }

  @spec new(Identity.t(), Capability.name(), Identity.portable_key()) ::
          {:ok, t()} | {:error, atom()}
  def new(owner, capability, id) do
    cond do
      not Identity.valid?(owner) ->
        {:error, :invalid_owner}

      not Capability.name?(capability) ->
        {:error, :unknown_capability}

      not Identity.portable_key?(id) ->
        {:error, :invalid_resource_id}

      true ->
        {:ok,
         %__MODULE__{
           owner: owner,
           capability: capability,
           id: id,
           generation: owner.generation
         }}
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = resource) do
    resource.generation == resource.owner.generation and
      match?({:ok, %__MODULE__{}}, new(resource.owner, resource.capability, resource.id))
  end

  def valid?(_resource), do: false
end
