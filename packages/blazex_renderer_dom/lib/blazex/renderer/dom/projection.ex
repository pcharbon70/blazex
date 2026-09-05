defmodule BlazeX.Renderer.DOM.Projection do
  @moduledoc "A bounded DOM node projection with no host object references."

  alias BlazeX.Renderer.DOM.{FocusIntent, Listener, SelectionIntent}

  @version 1
  @tags ["span", "div", "button", "input", "ul", "li", "section"]
  @enforce_keys [
    :version,
    :id,
    :tag,
    :text,
    :attributes,
    :listeners,
    :focus,
    :selection,
    :children
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          version: 1,
          id: binary(),
          tag: binary(),
          text: binary() | nil,
          attributes: %{optional(binary()) => binary()},
          listeners: [Listener.t()],
          focus: FocusIntent.t() | nil,
          selection: SelectionIntent.t() | nil,
          children: [t()]
        }

  def version, do: @version
  def tags, do: @tags

  @spec to_wire(t()) :: map()
  def to_wire(%__MODULE__{} = node) do
    %{
      "version" => node.version,
      "id" => node.id,
      "tag" => node.tag,
      "text" => node.text,
      "attributes" => node.attributes,
      "listeners" => Enum.map(node.listeners, &Listener.to_wire/1),
      "focus" => optional(node.focus, &FocusIntent.to_wire/1),
      "selection" => optional(node.selection, &SelectionIntent.to_wire/1),
      "children" => Enum.map(node.children, &to_wire/1)
    }
  end

  defp optional(nil, _mapper), do: nil
  defp optional(value, mapper), do: mapper.(value)
end
