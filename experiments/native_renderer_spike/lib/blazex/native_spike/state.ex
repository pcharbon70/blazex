defmodule BlazeX.NativeSpike.State do
  @moduledoc false

  alias BlazeX.NativeSpike.Batch

  @enforce_keys [:batch]
  defstruct @enforce_keys

  @type t :: %__MODULE__{batch: Batch.t()}
end
