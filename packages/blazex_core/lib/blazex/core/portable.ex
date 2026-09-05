defmodule BlazeX.Core.Portable do
  @moduledoc """
  Conservative validator for experimental component props and state.

  It admits bounded scalar, list, tuple, and plain-map data while rejecting
  processes, ports, references, functions, structs, and cyclic/opaque host
  values.
  """

  @max_depth 16
  @max_collection_size 256
  @max_binary_bytes 65_536

  @spec valid?(term()) :: boolean()
  def valid?(term), do: valid?(term, 0)

  defp valid?(_term, depth) when depth > @max_depth, do: false
  defp valid?(term, _depth) when is_atom(term) or is_integer(term) or is_float(term), do: true

  defp valid?(term, _depth) when is_binary(term) do
    byte_size(term) <= @max_binary_bytes and String.valid?(term)
  end

  defp valid?(term, depth) when is_tuple(term) do
    tuple_size(term) <= @max_collection_size and
      term
      |> Tuple.to_list()
      |> Enum.all?(&valid?(&1, depth + 1))
  end

  defp valid?(term, depth) when is_list(term) do
    with {:ok, size} <- proper_list_size(term),
         true <- size <= @max_collection_size do
      Enum.all?(term, &valid?(&1, depth + 1))
    else
      _ -> false
    end
  end

  defp valid?(term, depth) when is_map(term) do
    not is_struct(term) and map_size(term) <= @max_collection_size and
      Enum.all?(term, fn {key, value} -> valid?(key, depth + 1) and valid?(value, depth + 1) end)
  end

  defp valid?(_term, _depth), do: false

  defp proper_list_size(term), do: proper_list_size(term, 0)
  defp proper_list_size([], size), do: {:ok, size}

  defp proper_list_size([_head | _tail], size) when size == @max_collection_size,
    do: :error

  defp proper_list_size([_head | tail], size), do: proper_list_size(tail, size + 1)
  defp proper_list_size(_improper, _size), do: :error
end
