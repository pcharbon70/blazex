defmodule BlazeX.Renderer.Diagnostic do
  @moduledoc """
  Stable renderer-boundary failure data without backend-private error terms.
  """

  @enforce_keys [:code, :stage, :backend, :detail]
  defstruct [:code, :stage, :backend, :detail]

  @type t :: %__MODULE__{code: atom(), stage: atom(), backend: module() | nil, detail: term()}
end
