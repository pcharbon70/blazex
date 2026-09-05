defmodule BlazeX.Renderer.DOM.State do
  @moduledoc false

  alias BlazeX.Renderer.DOM.Batch

  @enforce_keys [:batch]
  defstruct @enforce_keys

  @type t :: %__MODULE__{batch: Batch.t()}
end
