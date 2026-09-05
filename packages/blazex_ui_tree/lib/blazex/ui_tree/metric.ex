defmodule BlazeX.UITree.Metric do
  @moduledoc """
  Logical, renderer-independent size and spacing values.

  Unit values are abstract logical units. Renderers own device conversion,
  intrinsic measurement, rounding, and final geometry.
  """

  alias BlazeX.UITree.TokenRef

  @max_units 1_000_000_000

  @type t :: :auto | :content | :fill | {:units, number()} | {:token, TokenRef.t()}

  @spec forms() :: [atom()]
  def forms, do: [:auto, :content, :fill, :units, :token]

  @spec units(number()) :: {:ok, t()} | {:error, :invalid_units}
  def units(value) do
    if valid_units?(value), do: {:ok, {:units, value}}, else: {:error, :invalid_units}
  end

  @spec token(TokenRef.t()) :: {:ok, t()} | {:error, :invalid_metric_token}
  def token(%TokenRef{category: category} = token) when category in [:space, :size] do
    if TokenRef.valid?(token), do: {:ok, {:token, token}}, else: {:error, :invalid_metric_token}
  end

  def token(_token), do: {:error, :invalid_metric_token}

  @spec valid?(term()) :: boolean()
  def valid?(value) when value in [:auto, :content, :fill], do: true
  def valid?({:units, value}), do: valid_units?(value)

  def valid?({:token, %TokenRef{category: category} = token}) when category in [:space, :size],
    do: TokenRef.valid?(token)

  def valid?(_value), do: false

  @spec spacing?(term()) :: boolean()
  def spacing?({:units, value}), do: valid_units?(value)
  def spacing?({:token, %TokenRef{category: :space} = token}), do: TokenRef.valid?(token)
  def spacing?(_value), do: false

  @spec bound?(term()) :: boolean()
  def bound?(nil), do: true
  def bound?({:units, value}), do: valid_units?(value)

  def bound?({:token, %TokenRef{category: category} = token}) when category in [:space, :size],
    do: TokenRef.valid?(token)

  def bound?(_value), do: false

  defp valid_units?(value) when is_integer(value), do: value in 0..@max_units

  defp valid_units?(value) when is_float(value),
    do: value >= 0.0 and value <= @max_units and value == value

  defp valid_units?(_value), do: false
end
