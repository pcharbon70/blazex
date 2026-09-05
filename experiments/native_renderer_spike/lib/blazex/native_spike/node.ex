defmodule BlazeX.NativeSpike.Node do
  @moduledoc "A closed platform-neutral native-control node in the experiment."

  @enforce_keys [
    :version,
    :id,
    :kind,
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
          kind: atom(),
          text: binary() | nil,
          attributes: map(),
          listeners: [map()],
          focus: map() | nil,
          selection: map() | nil,
          children: [t()]
        }
end
