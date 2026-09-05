defmodule BlazeX.UITree.Binding do
  @moduledoc """
  Semantic event binding from one source node to its owning component.
  """

  alias BlazeX.Core.{Event, Identity}

  @enforce_keys [:event, :owner, :source]
  defstruct [:event, :owner, :source]

  @type t :: %__MODULE__{event: Event.name(), owner: Identity.t(), source: Identity.t()}

  @spec new(Event.name(), Identity.t(), Identity.t()) ::
          {:ok, t()}
          | {:error, :unknown_event | :invalid_owner | :invalid_source | :source_outside_owner}
  def new(event, owner, source) do
    cond do
      not Event.name?(event) -> {:error, :unknown_event}
      not Identity.valid?(owner) -> {:error, :invalid_owner}
      not Identity.valid?(source) -> {:error, :invalid_source}
      not Identity.contains?(owner, source) -> {:error, :source_outside_owner}
      true -> {:ok, %__MODULE__{event: event, owner: owner, source: source}}
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = binding),
    do: match?({:ok, %__MODULE__{}}, new(binding.event, binding.owner, binding.source))

  def valid?(_binding), do: false
end
