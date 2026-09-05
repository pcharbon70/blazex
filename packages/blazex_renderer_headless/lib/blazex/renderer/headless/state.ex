defmodule BlazeX.Renderer.Headless.State do
  @moduledoc false

  alias BlazeX.Renderer.Headless.{Snapshot, Trace}

  @enforce_keys [:snapshot, :trace]
  defstruct @enforce_keys

  @type t :: %__MODULE__{snapshot: Snapshot.t(), trace: Trace.t()}
end
