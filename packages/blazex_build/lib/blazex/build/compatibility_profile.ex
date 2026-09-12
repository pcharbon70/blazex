defmodule BlazeX.Build.CompatibilityProfile do
  @moduledoc "Validated runtime-owned compatibility declaration for BH-06 builds."

  alias BlazeX.Build.JSON

  @enforce_keys [:id, :sha256, :runtime, :protocols, :features]
  defstruct @enforce_keys

  @top_keys ~w(features profile_id protocols runtime schema_version)
  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @version ~r/^[A-Za-z0-9][A-Za-z0-9._+-]{0,63}$/

  def new!(attributes) when is_map(attributes) do
    exact_keys!(attributes, @top_keys, "compatibility profile")
    identity!(attributes["schema_version"], attributes["profile_id"])
    runtime = runtime!(attributes["runtime"])
    protocols = protocols!(attributes["protocols"])
    features = features!(attributes["features"])

    normalized = %{
      "schema_version" => "1.0.0",
      "profile_id" => attributes["profile_id"],
      "runtime" => runtime,
      "protocols" => protocols |> Map.values() |> Enum.sort_by(& &1["id"]),
      "features" => features |> Map.values() |> Enum.sort_by(& &1["id"])
    }

    %__MODULE__{
      id: attributes["profile_id"],
      sha256: digest(normalized),
      runtime: runtime,
      protocols: protocols,
      features: features
    }
  end

  def new!(_), do: raise(ArgumentError, "compatibility profile must be a map")

  defp identity!("1.0.0", id) do
    unless bounded?(id, @id),
      do: raise(ArgumentError, "compatibility profile identity is invalid")
  end

  defp identity!(_, _), do: raise(ArgumentError, "compatibility profile identity is invalid")

  defp runtime!(runtime) when is_map(runtime) do
    exact_keys!(runtime, ~w(abi id version), "compatibility runtime")

    unless bounded?(runtime["id"], @id) and bounded?(runtime["abi"], @id) and
             bounded?(runtime["version"], @version),
           do: raise(ArgumentError, "compatibility runtime is invalid")

    runtime
  end

  defp runtime!(_), do: raise(ArgumentError, "compatibility runtime must be a map")

  defp protocols!(rows) when is_list(rows) do
    rows
    |> Enum.map(fn row ->
      unless is_map(row), do: raise(ArgumentError, "compatibility protocol is malformed")
      exact_keys!(row, ~w(id version), "compatibility protocol")

      unless bounded?(row["id"], @id) and bounded?(row["version"], @version),
        do: raise(ArgumentError, "compatibility protocol is invalid")

      row
    end)
    |> unique_map!("compatibility protocol")
  end

  defp protocols!(_), do: raise(ArgumentError, "compatibility protocols must be a list")

  defp features!(rows) when is_list(rows) do
    rows
    |> Enum.map(fn row ->
      unless is_map(row), do: raise(ArgumentError, "compatibility feature is malformed")
      exact_keys!(row, ~w(id reason state), "compatibility feature")

      unless bounded?(row["id"], @id) and row["state"] in ~w(supported unsupported) and
               reason?(row["reason"]),
             do: raise(ArgumentError, "compatibility feature is invalid")

      row
    end)
    |> unique_map!("compatibility feature")
  end

  defp features!(_), do: raise(ArgumentError, "compatibility features must be a list")

  defp unique_map!(rows, label) do
    duplicate =
      rows
      |> Enum.group_by(& &1["id"])
      |> Enum.filter(fn {_id, matches} -> length(matches) > 1 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()
      |> List.first()

    if duplicate, do: raise(ArgumentError, "duplicate #{label}: #{duplicate}")
    Map.new(rows, &{&1["id"], &1})
  end

  defp exact_keys!(value, keys, label) do
    unless Map.keys(value) |> Enum.sort() == Enum.sort(keys),
      do: raise(ArgumentError, "#{label} has missing or unknown fields")
  end

  defp bounded?(value, pattern), do: is_binary(value) and Regex.match?(pattern, value)

  defp reason?(value),
    do:
      is_binary(value) and byte_size(value) in 1..256 and
        not String.contains?(value, ["\n", "\r"])

  defp digest(value),
    do: :crypto.hash(:sha256, JSON.encode!(value) <> "\n") |> Base.encode16(case: :lower)
end
