defmodule BlazeX.UITree.ValidationError do
  @moduledoc """
  Deterministic semantic-tree rejection without retaining malformed values.
  """

  @enforce_keys [:code, :path]
  defstruct [:code, :path]

  @type code ::
          :malformed_node
          | :unsupported_version
          | :unknown_kind
          | :invalid_identity
          | :invalid_key
          | :key_identity_mismatch
          | :invalid_content
          | :invalid_children
          | :invalid_child_identity
          | :duplicate_sibling_identity
          | :duplicate_sibling_key

  @type t :: %__MODULE__{code: code(), path: [non_neg_integer()]}
end
