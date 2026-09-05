defmodule BlazeX.Renderer.DOM.FocusIntent do
  @moduledoc false

  alias BlazeX.UITree.Focus

  @enforce_keys [:behavior, :order, :auto_focus, :restore, :wrap]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          behavior: binary(),
          order: non_neg_integer() | nil,
          auto_focus: boolean(),
          restore: binary(),
          wrap: boolean()
        }

  def from(%Focus{} = focus) do
    %__MODULE__{
      behavior: Atom.to_string(focus.behavior),
      order: focus.order,
      auto_focus: focus.auto_focus,
      restore: Atom.to_string(focus.restore),
      wrap: focus.wrap
    }
  end

  def to_wire(%__MODULE__{} = focus) do
    %{
      "behavior" => focus.behavior,
      "order" => focus.order,
      "auto_focus" => focus.auto_focus,
      "restore" => focus.restore,
      "wrap" => focus.wrap
    }
  end
end
