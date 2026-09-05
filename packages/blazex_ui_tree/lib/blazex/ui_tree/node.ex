defmodule BlazeX.UITree.Node do
  @moduledoc """
  Experimental semantic node version 1.

  This representation intentionally has no renderer, event, effect, layout,
  token, accessibility, focus, selection, or resource fields.
  """

  alias BlazeX.Core.Identity
  alias BlazeX.UITree.ValidationError

  @version 1
  @kinds [:text, :group, :action, :field, :selection, :collection, :surface]
  @option_keys [:key, :content, :children]

  @enforce_keys [:version, :kind, :identity, :key, :content, :children]
  defstruct [:version, :kind, :identity, :key, :content, :children]

  @type kind :: :text | :group | :action | :field | :selection | :collection | :surface
  @type t :: %__MODULE__{
          version: 1,
          kind: kind(),
          identity: Identity.t(),
          key: Identity.portable_key() | nil,
          content: binary() | nil,
          children: [t()]
        }

  @spec version() :: 1
  def version, do: @version

  @spec kinds() :: [kind()]
  def kinds, do: @kinds

  @spec new(kind(), Identity.t(), keyword()) :: {:ok, t()} | {:error, ValidationError.t()}
  def new(kind, identity, options \\ [])

  def new(kind, identity, options) when is_list(options) do
    if Keyword.keyword?(options) and Enum.all?(Keyword.keys(options), &(&1 in @option_keys)) do
      node = %__MODULE__{
        version: @version,
        kind: kind,
        identity: identity,
        key: Keyword.get(options, :key),
        content: Keyword.get(options, :content),
        children: Keyword.get(options, :children, [])
      }

      case validate(node) do
        :ok -> {:ok, node}
        {:error, error} -> {:error, error}
      end
    else
      error(:malformed_node, [])
    end
  end

  def new(_kind, _identity, _options), do: error(:malformed_node, [])

  @spec text(Identity.t(), binary(), keyword()) :: {:ok, t()} | {:error, ValidationError.t()}
  def text(identity, content, options \\ [])

  def text(identity, content, options) when is_list(options) do
    if Keyword.keyword?(options) do
      new(:text, identity, Keyword.put(options, :content, content))
    else
      error(:malformed_node, [])
    end
  end

  def text(_identity, _content, _options), do: error(:malformed_node, [])

  @spec container(kind(), Identity.t(), [t()], keyword()) ::
          {:ok, t()} | {:error, ValidationError.t()}
  def container(kind, identity, children, options \\ [])

  def container(kind, identity, children, options) when is_list(options) do
    if Keyword.keyword?(options) do
      new(kind, identity, Keyword.put(options, :children, children))
    else
      error(:malformed_node, [])
    end
  end

  def container(_kind, _identity, _children, _options), do: error(:malformed_node, [])

  @spec validate(term()) :: :ok | {:error, ValidationError.t()}
  def validate(root), do: validate_node(root, [], nil)

  @spec preorder(term()) :: {:ok, [t()]} | {:error, ValidationError.t()}
  def preorder(root) do
    case validate(root) do
      :ok -> {:ok, collect_preorder(root)}
      {:error, error} -> {:error, error}
    end
  end

  defp validate_node(%__MODULE__{} = node, path, parent_identity) do
    with :ok <- validate_version(node, path),
         :ok <- validate_kind(node, path),
         :ok <- validate_identity(node, path),
         :ok <- validate_key(node, path),
         :ok <- validate_content(node, path),
         :ok <- validate_children_shape(node, path),
         :ok <- validate_ancestry(node, path, parent_identity),
         :ok <- validate_sibling_uniqueness(node.children, path),
         :ok <- validate_children(node, path) do
      :ok
    end
  end

  defp validate_node(_node, path, _parent_identity), do: error(:malformed_node, path)

  defp validate_version(%__MODULE__{version: @version}, _path), do: :ok
  defp validate_version(_node, path), do: error(:unsupported_version, path)

  defp validate_kind(%__MODULE__{kind: kind}, _path) when kind in @kinds, do: :ok
  defp validate_kind(_node, path), do: error(:unknown_kind, path)

  defp validate_identity(%__MODULE__{identity: identity}, path) do
    if Identity.valid?(identity), do: :ok, else: error(:invalid_identity, path)
  end

  defp validate_key(%__MODULE__{key: nil}, _path), do: :ok

  defp validate_key(%__MODULE__{key: key, identity: %Identity{path: identity_path}}, path) do
    cond do
      not Identity.portable_key?(key) -> error(:invalid_key, path)
      identity_path == [] -> error(:key_identity_mismatch, path)
      List.last(identity_path) != key -> error(:key_identity_mismatch, path)
      true -> :ok
    end
  end

  defp validate_key(_node, path), do: error(:invalid_key, path)

  defp validate_content(%__MODULE__{kind: :text, content: content, children: []}, path)
       when is_binary(content) and byte_size(content) > 0 do
    if String.valid?(content), do: :ok, else: error(:invalid_content, path)
  end

  defp validate_content(%__MODULE__{kind: :text}, path), do: error(:invalid_content, path)
  defp validate_content(%__MODULE__{content: nil}, _path), do: :ok
  defp validate_content(_node, path), do: error(:invalid_content, path)

  defp validate_children_shape(%__MODULE__{children: children}, path) do
    if proper_list?(children), do: :ok, else: error(:invalid_children, path)
  end

  defp validate_ancestry(_node, _path, nil), do: :ok

  defp validate_ancestry(
         %__MODULE__{identity: %Identity{} = identity},
         path,
         %Identity{} = parent
       ) do
    expected_prefix = parent.path

    if identity.root == parent.root and identity.generation == parent.generation and
         length(identity.path) == length(expected_prefix) + 1 and
         Enum.take(identity.path, length(expected_prefix)) == expected_prefix do
      :ok
    else
      error(:invalid_child_identity, path)
    end
  end

  defp validate_sibling_uniqueness(children, path) do
    with :ok <- reject_duplicate(children, &identity_of/1, :duplicate_sibling_identity, path),
         :ok <- reject_duplicate(children, &key_of/1, :duplicate_sibling_key, path) do
      :ok
    end
  end

  defp reject_duplicate(children, accessor, code, path) do
    result =
      Enum.reduce_while(children, MapSet.new(), fn child, seen ->
        case accessor.(child) do
          :ignore ->
            {:cont, seen}

          {:value, value} ->
            if MapSet.member?(seen, value) do
              {:halt, :duplicate}
            else
              {:cont, MapSet.put(seen, value)}
            end
        end
      end)

    if result == :duplicate, do: error(code, path), else: :ok
  end

  defp identity_of(%__MODULE__{identity: identity}), do: {:value, identity}
  defp identity_of(_child), do: :ignore
  defp key_of(%__MODULE__{key: nil}), do: :ignore
  defp key_of(%__MODULE__{key: key}), do: {:value, key}
  defp key_of(_child), do: :ignore

  defp validate_children(%__MODULE__{children: children, identity: parent_identity}, path) do
    children
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {child, index}, :ok ->
      case validate_node(child, path ++ [index], parent_identity) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp collect_preorder(%__MODULE__{children: children} = node) do
    [node | Enum.flat_map(children, &collect_preorder/1)]
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false

  defp error(code, path), do: {:error, %ValidationError{code: code, path: path}}
end
