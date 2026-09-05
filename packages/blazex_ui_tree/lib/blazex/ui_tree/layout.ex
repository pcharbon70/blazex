defmodule BlazeX.UITree.Layout do
  @moduledoc """
  Version-1 logical layout intent attached to one semantic node.

  This data constrains future renderer layout; it never contains calculated
  bounds, measurement callbacks, or renderer-owned objects.
  """

  alias BlazeX.Core.Identity
  alias BlazeX.UITree.Metric

  @version 1
  @modes [:none, :stack, :grid, :overlay]
  @directions [:row, :column]
  @alignments [:start, :center, :end, :stretch]
  @overflows [:visible, :clip, :scroll]
  @option_keys [
    :direction,
    :align,
    :gap,
    :padding,
    :width,
    :height,
    :min_width,
    :min_height,
    :max_width,
    :max_height,
    :grow,
    :overflow,
    :virtualization
  ]

  @enforce_keys [
    :version,
    :owner,
    :mode,
    :direction,
    :align,
    :gap,
    :padding,
    :width,
    :height,
    :min_width,
    :min_height,
    :max_width,
    :max_height,
    :grow,
    :overflow,
    :virtualization
  ]
  defstruct @enforce_keys

  @type virtualization :: %{
          axis: :row | :column,
          estimated_extent: Metric.t(),
          overscan: non_neg_integer()
        }
  @type t :: %__MODULE__{
          version: 1,
          owner: Identity.t(),
          mode: :none | :stack | :grid | :overlay,
          direction: :row | :column,
          align: :start | :center | :end | :stretch,
          gap: Metric.t(),
          padding: {Metric.t(), Metric.t(), Metric.t(), Metric.t()},
          width: Metric.t(),
          height: Metric.t(),
          min_width: Metric.t() | nil,
          min_height: Metric.t() | nil,
          max_width: Metric.t() | nil,
          max_height: Metric.t() | nil,
          grow: non_neg_integer(),
          overflow: :visible | :clip | :scroll,
          virtualization: virtualization() | nil
        }

  @spec modes() :: [atom()]
  def modes, do: @modes

  @spec directions() :: [atom()]
  def directions, do: @directions

  @spec alignments() :: [atom()]
  def alignments, do: @alignments

  @spec overflows() :: [atom()]
  def overflows, do: @overflows

  @spec new(Identity.t(), atom(), keyword()) :: {:ok, t()} | {:error, atom()}
  def new(owner, mode, options \\ [])

  def new(owner, mode, options) when is_list(options) do
    if Keyword.keyword?(options) and Enum.all?(Keyword.keys(options), &(&1 in @option_keys)) do
      zero = {:units, 0}

      layout = %__MODULE__{
        version: @version,
        owner: owner,
        mode: mode,
        direction: Keyword.get(options, :direction, :column),
        align: Keyword.get(options, :align, :stretch),
        gap: Keyword.get(options, :gap, zero),
        padding: Keyword.get(options, :padding, {zero, zero, zero, zero}),
        width: Keyword.get(options, :width, :auto),
        height: Keyword.get(options, :height, :auto),
        min_width: Keyword.get(options, :min_width),
        min_height: Keyword.get(options, :min_height),
        max_width: Keyword.get(options, :max_width),
        max_height: Keyword.get(options, :max_height),
        grow: Keyword.get(options, :grow, 0),
        overflow: Keyword.get(options, :overflow, :visible),
        virtualization: Keyword.get(options, :virtualization)
      }

      case validate(layout) do
        :ok -> {:ok, layout}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_layout_options}
    end
  end

  def new(_owner, _mode, _options), do: {:error, :invalid_layout_options}

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = layout) do
    cond do
      layout.version != @version ->
        {:error, :unsupported_layout_version}

      not Identity.valid?(layout.owner) ->
        {:error, :invalid_layout_owner}

      layout.mode not in @modes ->
        {:error, :unknown_layout_mode}

      layout.direction not in @directions ->
        {:error, :invalid_layout_direction}

      layout.align not in @alignments ->
        {:error, :invalid_layout_alignment}

      not Metric.spacing?(layout.gap) ->
        {:error, :invalid_layout_gap}

      not valid_padding?(layout.padding) ->
        {:error, :invalid_layout_padding}

      not Metric.valid?(layout.width) or not Metric.valid?(layout.height) ->
        {:error, :invalid_layout_size}

      not Enum.all?(
        [layout.min_width, layout.min_height, layout.max_width, layout.max_height],
        &Metric.bound?/1
      ) ->
        {:error, :invalid_layout_bound}

      not valid_range?(layout.min_width, layout.width, layout.max_width) ->
        {:error, :invalid_width_range}

      not valid_range?(layout.min_height, layout.height, layout.max_height) ->
        {:error, :invalid_height_range}

      not is_integer(layout.grow) or layout.grow not in 0..1_000_000 ->
        {:error, :invalid_layout_growth}

      layout.overflow not in @overflows ->
        {:error, :invalid_layout_overflow}

      not valid_virtualization?(layout.virtualization) ->
        {:error, :invalid_virtualization}

      layout.mode == :none and not is_nil(layout.virtualization) ->
        {:error, :invalid_virtualization}

      true ->
        :ok
    end
  end

  def validate(_layout), do: {:error, :malformed_layout}

  @spec valid?(term()) :: boolean()
  def valid?(layout), do: validate(layout) == :ok

  defp valid_padding?({top, right, bottom, left}),
    do: Enum.all?([top, right, bottom, left], &Metric.spacing?/1)

  defp valid_padding?(_padding), do: false

  defp valid_range?(minimum, value, maximum) do
    comparable_minimum?(minimum, value) and comparable_maximum?(value, maximum) and
      comparable_minimum?(minimum, maximum)
  end

  defp comparable_minimum?(nil, _right), do: true
  defp comparable_minimum?(_left, nil), do: true
  defp comparable_minimum?({:units, left}, {:units, right}), do: left <= right
  defp comparable_minimum?(_left, _right), do: true

  defp comparable_maximum?(_left, nil), do: true
  defp comparable_maximum?({:units, left}, {:units, right}), do: left <= right
  defp comparable_maximum?(_left, _right), do: true

  defp valid_virtualization?(nil), do: true

  defp valid_virtualization?(%{axis: axis, estimated_extent: extent, overscan: overscan} = value) do
    map_size(value) == 3 and axis in @directions and Metric.spacing?(extent) and
      extent != {:units, 0} and is_integer(overscan) and overscan in 0..1_000
  end

  defp valid_virtualization?(_virtualization), do: false
end
