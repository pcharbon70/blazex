defmodule BlazeX.Renderer.Capabilities do
  @moduledoc """
  Explicit renderer support declaration for the current experimental contract.
  """

  alias BlazeX.UITree.{Accessibility, Layout, Node}

  @version 1
  @tree_versions [1]
  @features [:event_bindings, :logical_layout, :accessibility, :focus, :selection]
  @option_keys [:tree_versions, :node_kinds, :layout_modes, :accessibility_roles, :features]

  @enforce_keys [
    :version,
    :tree_versions,
    :node_kinds,
    :layout_modes,
    :accessibility_roles,
    :features
  ]
  defstruct @enforce_keys

  @type feature :: :event_bindings | :logical_layout | :accessibility | :focus | :selection
  @type t :: %__MODULE__{
          version: 1,
          tree_versions: [1],
          node_kinds: [Node.kind()],
          layout_modes: [atom()],
          accessibility_roles: [Accessibility.role()],
          features: [feature()]
        }

  @spec features() :: [feature()]
  def features, do: @features

  @spec tree_versions() :: [1]
  def tree_versions, do: @tree_versions

  @spec full() :: t()
  def full do
    {:ok, capabilities} =
      new(
        tree_versions: @tree_versions,
        node_kinds: Node.kinds(),
        layout_modes: Layout.modes(),
        accessibility_roles: Accessibility.roles(),
        features: @features
      )

    capabilities
  end

  @spec new(keyword()) :: {:ok, t()} | {:error, atom()}
  def new(options) when is_list(options) do
    if Keyword.keyword?(options) and Enum.sort(Keyword.keys(options)) == Enum.sort(@option_keys) do
      capabilities = %__MODULE__{
        version: @version,
        tree_versions: Keyword.fetch!(options, :tree_versions),
        node_kinds: Keyword.fetch!(options, :node_kinds),
        layout_modes: Keyword.fetch!(options, :layout_modes),
        accessibility_roles: Keyword.fetch!(options, :accessibility_roles),
        features: Keyword.fetch!(options, :features)
      }

      case validate(capabilities) do
        :ok -> {:ok, capabilities}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_capability_options}
    end
  end

  def new(_options), do: {:error, :invalid_capability_options}

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = capabilities) do
    cond do
      capabilities.version != @version ->
        {:error, :unsupported_capability_version}

      not canonical_subset?(capabilities.tree_versions, @tree_versions) ->
        {:error, :invalid_tree_versions}

      not canonical_subset?(capabilities.node_kinds, Node.kinds()) ->
        {:error, :invalid_node_kinds}

      not canonical_subset?(capabilities.layout_modes, Layout.modes()) ->
        {:error, :invalid_layout_modes}

      not canonical_subset?(capabilities.accessibility_roles, Accessibility.roles()) ->
        {:error, :invalid_accessibility_roles}

      not canonical_subset?(capabilities.features, @features) ->
        {:error, :invalid_renderer_features}

      true ->
        :ok
    end
  end

  def validate(_capabilities), do: {:error, :malformed_capabilities}

  @spec valid?(term()) :: boolean()
  def valid?(capabilities), do: validate(capabilities) == :ok

  defp canonical_subset?(values, vocabulary) when is_list(values) do
    proper_list?(values) and values == Enum.filter(vocabulary, &(&1 in values))
  end

  defp canonical_subset?(_values, _vocabulary), do: false

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false
end
