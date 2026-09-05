defmodule BlazeX.UITree.Focus do
  @moduledoc """
  Version-1 focus participation and scope intent.

  It describes ordering and restoration without executing a host focus call.
  """

  alias BlazeX.Core.Identity

  @version 1
  @behaviors [:none, :target, :scope]
  @restore_values [:none, :previous]
  @max_order 1_000_000
  @option_keys [:order, :auto_focus, :restore, :wrap]

  @enforce_keys [:version, :owner, :behavior, :order, :auto_focus, :restore, :wrap]
  defstruct @enforce_keys

  @type behavior :: :none | :target | :scope
  @type t :: %__MODULE__{
          version: 1,
          owner: Identity.t(),
          behavior: behavior(),
          order: non_neg_integer() | nil,
          auto_focus: boolean(),
          restore: :none | :previous,
          wrap: boolean()
        }

  @spec behaviors() :: [behavior()]
  def behaviors, do: @behaviors

  @spec restore_values() :: [:none | :previous]
  def restore_values, do: @restore_values

  @spec new(Identity.t(), behavior(), keyword()) :: {:ok, t()} | {:error, atom()}
  def new(owner, behavior, options \\ [])

  def new(owner, behavior, options) when is_list(options) do
    if Keyword.keyword?(options) and Enum.all?(Keyword.keys(options), &(&1 in @option_keys)) do
      focus = %__MODULE__{
        version: @version,
        owner: owner,
        behavior: behavior,
        order: Keyword.get(options, :order),
        auto_focus: Keyword.get(options, :auto_focus, false),
        restore: Keyword.get(options, :restore, :none),
        wrap: Keyword.get(options, :wrap, false)
      }

      case validate(focus) do
        :ok -> {:ok, focus}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_focus_options}
    end
  end

  def new(_owner, _behavior, _options), do: {:error, :invalid_focus_options}

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = focus) do
    cond do
      focus.version != @version ->
        {:error, :unsupported_focus_version}

      not Identity.valid?(focus.owner) ->
        {:error, :invalid_focus_owner}

      focus.behavior not in @behaviors ->
        {:error, :unknown_focus_behavior}

      not is_boolean(focus.auto_focus) or not is_boolean(focus.wrap) ->
        {:error, :invalid_focus_flag}

      focus.restore not in @restore_values ->
        {:error, :invalid_focus_restore}

      not valid_shape?(focus) ->
        {:error, :invalid_focus_shape}

      true ->
        :ok
    end
  end

  def validate(_focus), do: {:error, :malformed_focus}

  @spec valid?(term()) :: boolean()
  def valid?(focus), do: validate(focus) == :ok

  defp valid_shape?(%__MODULE__{behavior: :none} = focus),
    do: is_nil(focus.order) and not focus.auto_focus and focus.restore == :none and not focus.wrap

  defp valid_shape?(%__MODULE__{behavior: :target} = focus),
    do: valid_order?(focus.order) and focus.restore == :none and not focus.wrap

  defp valid_shape?(%__MODULE__{behavior: :scope} = focus),
    do: is_nil(focus.order) and not focus.auto_focus

  defp valid_order?(order), do: is_integer(order) and order in 0..@max_order
end
