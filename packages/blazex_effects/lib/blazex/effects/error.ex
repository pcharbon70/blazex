defmodule BlazeX.Effects.Error do
  @moduledoc """
  Stable rejection data for capability, effect, and resource operations.
  """

  @enforce_keys [:code, :stage]
  defstruct [:code, :stage, :detail]

  @type t :: %__MODULE__{code: atom(), stage: atom(), detail: atom() | nil}
end
