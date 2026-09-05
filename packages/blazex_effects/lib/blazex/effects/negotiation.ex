defmodule BlazeX.Effects.Negotiation do
  @moduledoc """
  Deny-by-default capability negotiation result.
  """

  alias BlazeX.Effects.{Capability, Error}

  @enforce_keys [:granted, :fallbacks, :omitted]
  defstruct [:granted, :fallbacks, :omitted]

  @type t :: %__MODULE__{
          granted: [Capability.name()],
          fallbacks: [Capability.name()],
          omitted: [Capability.name()]
        }

  @spec negotiate([Capability.t()], [Capability.name()]) :: {:ok, t()} | {:error, Error.t()}
  def negotiate(requirements, grants) do
    with :ok <- validate_requirements(requirements),
         :ok <- validate_grants(grants) do
      reduce_requirements(requirements, MapSet.new(grants))
    end
  end

  defp reduce_requirements(requirements, grants) do
    initial = %__MODULE__{granted: [], fallbacks: [], omitted: []}

    requirements
    |> Enum.reduce_while({:ok, initial}, fn requirement, {:ok, result} ->
      cond do
        MapSet.member?(grants, requirement.name) ->
          {:cont, {:ok, %{result | granted: result.granted ++ [requirement.name]}}}

        requirement.fallback == :component ->
          {:cont, {:ok, %{result | fallbacks: result.fallbacks ++ [requirement.name]}}}

        requirement.requirement == :optional and requirement.fallback == :omit ->
          {:cont, {:ok, %{result | omitted: result.omitted ++ [requirement.name]}}}

        true ->
          {:halt, error(:required_capability_missing, :negotiate, requirement.name)}
      end
    end)
  end

  defp validate_requirements(requirements) when is_list(requirements) do
    if proper_list?(requirements) do
      if Enum.all?(requirements, &Capability.valid?/1) do
        names = Enum.map(requirements, & &1.name)

        if length(names) == MapSet.size(MapSet.new(names)),
          do: :ok,
          else: error(:duplicate_requirement, :negotiate)
      else
        error(:invalid_requirement, :negotiate)
      end
    else
      error(:invalid_requirement, :negotiate)
    end
  end

  defp validate_requirements(_requirements), do: error(:invalid_requirement, :negotiate)

  defp validate_grants(grants) when is_list(grants) do
    if proper_list?(grants) do
      cond do
        not Enum.all?(grants, &Capability.name?/1) -> error(:unknown_grant, :negotiate)
        length(grants) != MapSet.size(MapSet.new(grants)) -> error(:duplicate_grant, :negotiate)
        true -> :ok
      end
    else
      error(:invalid_grants, :negotiate)
    end
  end

  defp validate_grants(_grants), do: error(:invalid_grants, :negotiate)

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false

  defp error(code, stage, detail \\ nil),
    do: {:error, %Error{code: code, stage: stage, detail: detail}}
end
