defmodule BlazeX.UITree.TokenRef do
  @moduledoc """
  Version-1 reference to a renderer-resolved design token.

  A token reference carries category and portable name only. It does not carry
  a concrete color, font, stylesheet value, or renderer resource.
  """

  alias BlazeX.Core.Identity

  @version 1
  @categories [:space, :size, :color, :typography, :radius, :motion]

  @enforce_keys [:version, :category, :name]
  defstruct [:version, :category, :name]

  @type category :: :space | :size | :color | :typography | :radius | :motion
  @type t :: %__MODULE__{version: 1, category: category(), name: Identity.portable_key()}

  @spec categories() :: [category()]
  def categories, do: @categories

  @spec new(category(), Identity.portable_key()) :: {:ok, t()} | {:error, atom()}
  def new(category, name) do
    cond do
      category not in @categories -> {:error, :unknown_token_category}
      not Identity.portable_key?(name) -> {:error, :invalid_token_name}
      true -> {:ok, %__MODULE__{version: @version, category: category, name: name}}
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = token) do
    token.version == @version and
      match?({:ok, %__MODULE__{}}, new(token.category, token.name))
  end

  def valid?(_token), do: false
end
