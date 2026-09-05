defmodule BlazeX.Renderer.DOM.Listener do
  @moduledoc "A plain semantic-to-native event listener projection."

  alias BlazeX.Renderer.DOM.Portable
  alias BlazeX.UITree.Binding

  @native_events %{
    activate: "click",
    change: "input",
    submit: "submit",
    select: "change",
    expand: "click",
    dismiss: "click",
    move: "pointermove",
    reorder: "drop",
    increment: "click",
    decrement: "click",
    request_open: "click",
    request_close: "click",
    request_page: "click"
  }

  @enforce_keys [:semantic, :native, :owner, :source]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          semantic: binary(),
          native: binary(),
          owner: map(),
          source: map()
        }

  @spec new(Binding.t()) :: t()
  def new(%Binding{} = binding) do
    %__MODULE__{
      semantic: Atom.to_string(binding.event),
      native: Map.fetch!(@native_events, binding.event),
      owner: Portable.identity(binding.owner),
      source: Portable.identity(binding.source)
    }
  end

  @spec to_wire(t()) :: map()
  def to_wire(%__MODULE__{} = listener) do
    %{
      "semantic" => listener.semantic,
      "native" => listener.native,
      "owner" => listener.owner,
      "source" => listener.source
    }
  end
end
