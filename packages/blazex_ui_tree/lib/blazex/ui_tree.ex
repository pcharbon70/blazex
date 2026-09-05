defmodule BlazeX.UITree do
  @moduledoc """
  Experimental version-1 semantic UI tree.

  Phase 2 owns a bounded node vocabulary, deterministic validation, and
  traversal. Layout, tokens, accessibility, focus, selection, resources,
  events, renderer extensions, and patches remain deferred to later phases.
  """

  alias BlazeX.UITree.{Node, ValidationError}

  @spec validate(term()) :: :ok | {:error, ValidationError.t()}
  def validate(root), do: Node.validate(root)

  @spec preorder(term()) :: {:ok, [Node.t()]} | {:error, ValidationError.t()}
  def preorder(root), do: Node.preorder(root)
end
