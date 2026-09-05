defmodule BlazeX.Renderer.Headless.Trace.Entry do
  @moduledoc "One deterministic renderer lifecycle observation."

  alias BlazeX.Core.Identity

  @enforce_keys [:sequence, :transition, :owner, :generation, :revision, :digest]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          sequence: pos_integer(),
          transition: :mount | :update | :replace | :dispose,
          owner: Identity.t(),
          generation: pos_integer(),
          revision: non_neg_integer(),
          digest: binary()
        }
end

defmodule BlazeX.Renderer.Headless.Trace do
  @moduledoc "Ordered deterministic headless lifecycle trace."

  alias BlazeX.Renderer.Context
  alias BlazeX.Renderer.Headless.Trace.Entry

  @version 1
  @enforce_keys [:version, :entries]
  defstruct @enforce_keys

  @type t :: %__MODULE__{version: 1, entries: [Entry.t()]}

  @spec new() :: t()
  def new, do: %__MODULE__{version: @version, entries: []}

  @spec append(t(), Context.t(), binary()) :: t()
  def append(%__MODULE__{} = trace, %Context{} = context, digest) do
    entry = %Entry{
      sequence: length(trace.entries) + 1,
      transition: context.transition,
      owner: context.owner,
      generation: context.generation,
      revision: context.revision,
      digest: digest
    }

    %{trace | entries: trace.entries ++ [entry]}
  end
end
