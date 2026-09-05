defmodule BlazeX.Renderer.Requirements do
  @moduledoc """
  Renderer requirements derived from a complete validated semantic output.
  """

  alias BlazeX.UITree.{Accessibility, Document, IntentSet, Layout, Node}

  @enforce_keys [:tree_version, :node_kinds, :layout_modes, :accessibility_roles, :features]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          tree_version: 1,
          node_kinds: [Node.kind()],
          layout_modes: [atom()],
          accessibility_roles: [Accessibility.role()],
          features: [atom()]
        }

  @spec derive(term()) :: {:ok, t()} | {:error, atom()}
  def derive(%Node{} = node) do
    with :ok <- Node.validate(node), do: derive_from(node, [], [], [])
  end

  def derive(%Document{} = document) do
    with :ok <- Document.validate(document) do
      features = if document.bindings == [], do: [], else: [:event_bindings]
      derive_from(document.root, [], [], features)
    end
  end

  def derive(%IntentSet{} = intent_set) do
    with :ok <- IntentSet.validate(intent_set) do
      features =
        []
        |> include(intent_set.document.bindings != [], :event_bindings)
        |> include(intent_set.layouts != [], :logical_layout)
        |> include(intent_set.accessibility != [], :accessibility)
        |> include(intent_set.focus != [], :focus)
        |> include(intent_set.selections != [], :selection)

      derive_from(
        intent_set.document.root,
        Enum.map(intent_set.layouts, & &1.mode),
        Enum.map(intent_set.accessibility, & &1.role),
        features
      )
    end
  end

  def derive(_output), do: {:error, :invalid_semantic_output}

  defp derive_from(root, layout_modes, accessibility_roles, features) do
    {:ok, nodes} = Node.preorder(root)

    {:ok,
     %__MODULE__{
       tree_version: Node.version(),
       node_kinds: canonical_unique(Enum.map(nodes, & &1.kind), Node.kinds()),
       layout_modes: canonical_unique(layout_modes, Layout.modes()),
       accessibility_roles: canonical_unique(accessibility_roles, Accessibility.roles()),
       features: features
     }}
  end

  defp include(values, true, value), do: values ++ [value]
  defp include(values, false, _value), do: values

  defp canonical_unique(values, vocabulary),
    do: Enum.filter(vocabulary, &(&1 in values))
end
