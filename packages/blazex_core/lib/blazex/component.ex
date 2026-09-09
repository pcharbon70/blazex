defmodule BlazeX.Component do
  @moduledoc """
  Experimental BH-05 authoring facade. For example:

      use BlazeX.Component, role: :pure
      def render(_input), do: {:output, {:semantic, 1, %{kind: :text, content: "Hello"}}}

  This declares a contract, not a running component or a sandbox. Only static
  metadata is generated. Inputs and results must be validated by a future
  evaluator before any commit. Semantic candidates require UI-tree validation.
  """

  defmacro __using__(options) do
    BlazeX.Core.Authoring.declare!(__CALLER__, options)
  end
end
