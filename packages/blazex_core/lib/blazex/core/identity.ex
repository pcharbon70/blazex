defmodule BlazeX.Core.Identity do
  @moduledoc """
  Experimental structural identity for a component or semantic node.

  Identity consists only of a portable root key, an ordered path of portable
  keys, and a positive generation. Updates and keyed moves retain the complete
  value. Replacement advances the generation rather than renaming an instance.
  """

  @max_binary_bytes 256
  @max_collection_size 32
  @max_depth 8
  @max_generation 9_223_372_036_854_775_807

  @enforce_keys [:root, :path, :generation]
  defstruct [:root, :path, :generation]

  @type portable_key ::
          atom()
          | binary()
          | integer()
          | [portable_key()]
          | tuple()

  @type t :: %__MODULE__{
          root: portable_key(),
          path: [portable_key()],
          generation: pos_integer()
        }

  @spec new(portable_key(), pos_integer()) ::
          {:ok, t()} | {:error, :invalid_root | :invalid_generation}
  def new(root, generation \\ 1) do
    cond do
      not portable_key?(root) -> {:error, :invalid_root}
      not valid_generation?(generation) -> {:error, :invalid_generation}
      true -> {:ok, %__MODULE__{root: root, path: [], generation: generation}}
    end
  end

  @spec child(t(), portable_key()) ::
          {:ok, t()} | {:error, :invalid_identity | :invalid_key | :path_exhausted}
  def child(%__MODULE__{} = parent, key) do
    cond do
      not valid?(parent) -> {:error, :invalid_identity}
      not portable_key?(key) -> {:error, :invalid_key}
      length(parent.path) == @max_collection_size -> {:error, :path_exhausted}
      true -> {:ok, %{parent | path: parent.path ++ [key]}}
    end
  end

  def child(_parent, _key), do: {:error, :invalid_identity}

  @spec replace(t()) :: {:ok, t()} | {:error, :invalid_identity | :generation_exhausted}
  def replace(%__MODULE__{} = identity) do
    cond do
      not valid?(identity) -> {:error, :invalid_identity}
      identity.generation == @max_generation -> {:error, :generation_exhausted}
      true -> {:ok, %{identity | generation: identity.generation + 1}}
    end
  end

  def replace(_identity), do: {:error, :invalid_identity}

  @spec contains?(t(), t()) :: boolean()
  def contains?(%__MODULE__{} = owner, %__MODULE__{} = candidate) do
    valid?(owner) and valid?(candidate) and owner.root == candidate.root and
      owner.generation == candidate.generation and
      Enum.take(candidate.path, length(owner.path)) == owner.path
  end

  def contains?(_owner, _candidate), do: false

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{root: root, path: path, generation: generation}) do
    portable_key?(root) and valid_path?(path) and valid_generation?(generation)
  end

  def valid?(_identity), do: false

  @spec portable_key?(term()) :: boolean()
  def portable_key?(term), do: portable_key?(term, 0)

  defp portable_key?(_term, depth) when depth > @max_depth, do: false
  defp portable_key?(term, _depth) when is_atom(term), do: not is_nil(term)
  defp portable_key?(term, _depth) when is_integer(term), do: true

  defp portable_key?(term, _depth) when is_binary(term) do
    byte_size(term) in 1..@max_binary_bytes and String.valid?(term)
  end

  defp portable_key?(term, depth) when is_tuple(term) do
    tuple_size(term) in 1..@max_collection_size and
      term
      |> Tuple.to_list()
      |> Enum.all?(&portable_key?(&1, depth + 1))
  end

  defp portable_key?(term, depth) when is_list(term) do
    with {:ok, size} <- proper_list_size(term),
         true <- size in 1..@max_collection_size do
      Enum.all?(term, &portable_key?(&1, depth + 1))
    else
      _ -> false
    end
  end

  defp portable_key?(_term, _depth), do: false

  defp valid_path?(path) when is_list(path) do
    case proper_list_size(path) do
      {:ok, size} when size <= @max_collection_size -> Enum.all?(path, &portable_key?/1)
      _ -> false
    end
  end

  defp valid_path?(_path), do: false

  defp valid_generation?(generation),
    do: is_integer(generation) and generation in 1..@max_generation

  defp proper_list_size(term), do: proper_list_size(term, 0)
  defp proper_list_size([], size), do: {:ok, size}

  defp proper_list_size([_head | _tail], size) when size == @max_collection_size,
    do: :error

  defp proper_list_size([_head | tail], size), do: proper_list_size(tail, size + 1)
  defp proper_list_size(_improper, _size), do: :error
end
