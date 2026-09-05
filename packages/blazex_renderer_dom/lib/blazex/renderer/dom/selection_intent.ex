defmodule BlazeX.Renderer.DOM.SelectionIntent do
  @moduledoc false

  alias BlazeX.Renderer.DOM.Portable
  alias BlazeX.UITree.Selection

  @enforce_keys [:kind, :value]
  defstruct @enforce_keys

  @type t :: %__MODULE__{kind: binary(), value: term()}

  def from(%Selection{kind: :none}), do: %__MODULE__{kind: "none", value: nil}

  def from(%Selection{kind: :single, value: value}),
    do: %__MODULE__{kind: "single", value: Portable.encode(value)}

  def from(%Selection{kind: :multiple, value: values}),
    do: %__MODULE__{kind: "multiple", value: Enum.map(values, &Portable.encode/1)}

  def from(%Selection{kind: :text_range, value: value}) do
    %__MODULE__{
      kind: "text_range",
      value: %{
        "anchor" => value.anchor,
        "focus" => value.focus,
        "direction" => Atom.to_string(value.direction)
      }
    }
  end

  def to_wire(%__MODULE__{} = selection),
    do: %{"kind" => selection.kind, "value" => selection.value}
end
