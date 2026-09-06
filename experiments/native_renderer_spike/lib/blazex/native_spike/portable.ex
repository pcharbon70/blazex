defmodule BlazeX.NativeSpike.Portable do
  @moduledoc false

  alias BlazeX.Core.Identity

  def identity(%Identity{} = identity) do
    %{
      root: encode(identity.root),
      path: Enum.map(identity.path, &encode/1),
      generation: identity.generation
    }
  end

  def id(%Identity{} = identity) do
    suffix =
      identity
      |> identity()
      |> :erlang.term_to_binary([:deterministic])
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 24)

    "bn-" <> suffix
  end

  def encode(value) when is_atom(value), do: %{type: :atom, value: Atom.to_string(value)}
  def encode(value) when is_binary(value), do: %{type: :binary, value: value}
  def encode(value) when is_integer(value), do: %{type: :integer, value: value}
  def encode(value) when is_list(value), do: %{type: :list, value: Enum.map(value, &encode/1)}

  def encode(value) when is_tuple(value),
    do: %{type: :tuple, value: value |> Tuple.to_list() |> Enum.map(&encode/1)}
end
