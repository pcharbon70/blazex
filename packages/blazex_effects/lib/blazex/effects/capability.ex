defmodule BlazeX.Effects.Capability do
  @moduledoc """
  Experimental capability requirement and fallback policy.
  """

  @version 1
  @names [:time, :"ui.clipboard", :"ui.files.choose", :"ui.storage"]
  @operations %{
    :time => [:schedule],
    :"ui.clipboard" => [:read, :write],
    :"ui.files.choose" => [:choose],
    :"ui.storage" => [:get, :put, :delete]
  }

  @enforce_keys [:version, :name, :requirement, :fallback]
  defstruct [:version, :name, :requirement, :fallback]

  @type name :: :time | :"ui.clipboard" | :"ui.files.choose" | :"ui.storage"
  @type requirement :: :required | :optional
  @type fallback :: :fail | :omit | :component
  @type t :: %__MODULE__{
          version: 1,
          name: name(),
          requirement: requirement(),
          fallback: fallback()
        }

  @spec names() :: [name()]
  def names, do: @names

  @spec operations() :: %{name() => [atom()]}
  def operations, do: @operations

  @spec name?(term()) :: boolean()
  def name?(name), do: name in @names

  @spec operation?(name(), term()) :: boolean()
  def operation?(name, operation), do: operation in Map.get(@operations, name, [])

  @spec new(name(), requirement(), fallback()) :: {:ok, t()} | {:error, atom()}
  def new(name, requirement, fallback) do
    cond do
      not name?(name) ->
        {:error, :unknown_capability}

      requirement not in [:required, :optional] ->
        {:error, :invalid_requirement}

      fallback not in [:fail, :omit, :component] ->
        {:error, :invalid_fallback}

      requirement == :required and fallback == :omit ->
        {:error, :invalid_fallback}

      requirement == :optional and fallback == :fail ->
        {:error, :invalid_fallback}

      true ->
        {:ok,
         %__MODULE__{
           version: @version,
           name: name,
           requirement: requirement,
           fallback: fallback
         }}
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = capability) do
    capability.version == @version and
      match?(
        {:ok, %__MODULE__{}},
        new(capability.name, capability.requirement, capability.fallback)
      )
  end

  def valid?(_capability), do: false
end
