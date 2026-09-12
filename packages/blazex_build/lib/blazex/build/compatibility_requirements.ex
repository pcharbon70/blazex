defmodule BlazeX.Build.CompatibilityRequirements do
  @moduledoc "Validated application requirements for an exact BH-06 runtime profile."

  alias BlazeX.Build.{CompatibilityProfile, JSON}

  @enforce_keys [:id, :sha256, :runtime, :protocols, :features]
  defstruct @enforce_keys

  def new!(attributes) when is_map(attributes) do
    profile_shape = Map.put(attributes, "profile_id", attributes["requirement_id"])
    profile_shape = Map.delete(profile_shape, "requirement_id")

    feature_rows =
      case attributes["features"] do
        rows when is_list(rows) ->
          Enum.map(rows, fn id ->
            %{"id" => id, "state" => "supported", "reason" => "required by candidate"}
          end)

        _ ->
          raise ArgumentError, "compatibility requirement features must be a list"
      end

    profile = CompatibilityProfile.new!(Map.put(profile_shape, "features", feature_rows))
    features = Map.keys(profile.features) |> Enum.sort()

    normalized = %{
      "schema_version" => "1.0.0",
      "requirement_id" => attributes["requirement_id"],
      "runtime" => profile.runtime,
      "protocols" => profile.protocols |> Map.values() |> Enum.sort_by(& &1["id"]),
      "features" => features
    }

    %__MODULE__{
      id: attributes["requirement_id"],
      sha256: digest(normalized),
      runtime: profile.runtime,
      protocols: profile.protocols,
      features: features
    }
  rescue
    error in ArgumentError ->
      message = Exception.message(error) |> String.replace("profile", "requirements")
      reraise ArgumentError, [message: message], __STACKTRACE__
  end

  def new!(_), do: raise(ArgumentError, "compatibility requirements must be a map")

  defp digest(value),
    do: :crypto.hash(:sha256, JSON.encode!(value) <> "\n") |> Base.encode16(case: :lower)
end
