defmodule BlazeX.UITree.Selection do
  @moduledoc """
  Version-1 controlled semantic selection state.
  """

  alias BlazeX.Core.Identity

  @version 1
  @kinds [:none, :single, :multiple, :text_range]
  @directions [:forward, :backward]
  @max_offset 1_000_000_000
  @max_values 256

  @enforce_keys [:version, :owner, :kind, :value]
  defstruct @enforce_keys

  @type text_range :: %{
          anchor: non_neg_integer(),
          focus: non_neg_integer(),
          direction: :forward | :backward
        }
  @type t :: %__MODULE__{
          version: 1,
          owner: Identity.t(),
          kind: :none | :single | :multiple | :text_range,
          value: nil | Identity.portable_key() | [Identity.portable_key()] | text_range()
        }

  @spec kinds() :: [atom()]
  def kinds, do: @kinds

  @spec directions() :: [atom()]
  def directions, do: @directions

  @spec new(Identity.t(), atom(), term()) :: {:ok, t()} | {:error, atom()}
  def new(owner, kind, value \\ nil) do
    selection = %__MODULE__{version: @version, owner: owner, kind: kind, value: value}

    case validate(selection) do
      :ok -> {:ok, selection}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = selection) do
    cond do
      selection.version != @version -> {:error, :unsupported_selection_version}
      not Identity.valid?(selection.owner) -> {:error, :invalid_selection_owner}
      selection.kind not in @kinds -> {:error, :unknown_selection_kind}
      not valid_value?(selection.kind, selection.value) -> {:error, :invalid_selection_value}
      true -> :ok
    end
  end

  def validate(_selection), do: {:error, :malformed_selection}

  @spec valid?(term()) :: boolean()
  def valid?(selection), do: validate(selection) == :ok

  defp valid_value?(:none, nil), do: true
  defp valid_value?(:single, value), do: Identity.portable_key?(value)

  defp valid_value?(:multiple, values) do
    proper_list?(values) and length(values) <= @max_values and
      Enum.all?(values, &Identity.portable_key?/1) and
      length(values) == MapSet.size(MapSet.new(values))
  end

  defp valid_value?(:text_range, %{anchor: anchor, focus: focus, direction: direction} = value) do
    map_size(value) == 3 and valid_offset?(anchor) and valid_offset?(focus) and
      direction in @directions
  end

  defp valid_value?(_kind, _value), do: false

  defp valid_offset?(offset), do: is_integer(offset) and offset in 0..@max_offset

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false
end
