defmodule BlazeX.Core.Context do
  @moduledoc """
  Immutable context supplied during one component evaluation transition.
  """

  alias BlazeX.Core.Identity

  @enforce_keys [:identity, :revision, :transition]
  defstruct [:identity, :revision, :transition]

  @type transition :: :mount | :update | :replace
  @type t :: %__MODULE__{
          identity: Identity.t(),
          revision: non_neg_integer(),
          transition: transition()
        }
end
