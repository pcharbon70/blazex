defmodule BlazeX.Build.Compatibility do
  @moduledoc "Deterministic exact compatibility evaluation for BH-06 candidates."

  alias BlazeX.Build.{CompatibilityError, CompatibilityProfile, CompatibilityRequirements}

  def evaluate!(%CompatibilityProfile{} = profile, %CompatibilityRequirements{} = requirements) do
    report = evaluate(profile, requirements)
    if report["compatible"], do: report, else: raise(CompatibilityError, report: report)
  end

  def evaluate!(_, _),
    do: raise(ArgumentError, "compatibility evaluation requires a profile and requirements")

  def evaluate(%CompatibilityProfile{} = profile, %CompatibilityRequirements{} = requirements) do
    runtime = runtime_rows(profile.runtime, requirements.runtime)
    protocols = protocol_rows(profile.protocols, requirements.protocols)
    features = feature_rows(profile.features, requirements.features)

    violations =
      (runtime ++ protocols ++ features)
      |> Enum.reject(& &1["compatible"])
      |> Enum.map(&violation/1)
      |> Enum.sort_by(&{&1["kind"], &1["subject"]})

    unused_protocols = Map.keys(profile.protocols) -- Map.keys(requirements.protocols)
    unused_features = Map.keys(profile.features) -- requirements.features

    %{
      "schema_version" => "1.0.0",
      "profile_id" => profile.id,
      "profile_sha256" => profile.sha256,
      "requirement_id" => requirements.id,
      "requirements_sha256" => requirements.sha256,
      "runtime" => runtime,
      "protocols" => protocols,
      "features" => features,
      "unused_profile" => %{
        "protocols" => Enum.sort(unused_protocols),
        "features" => Enum.sort(unused_features)
      },
      "violations" => violations,
      "summary" => %{
        "runtime_requirements" => length(runtime),
        "protocol_requirements" => length(protocols),
        "feature_requirements" => length(features),
        "matched" => Enum.count(runtime ++ protocols ++ features, & &1["compatible"]),
        "violations" => length(violations)
      },
      "compatible" => violations == []
    }
  end

  def evaluate(_, _),
    do: raise(ArgumentError, "compatibility evaluation requires a profile and requirements")

  defp runtime_rows(actual, expected) do
    for field <- ~w(id version abi) do
      row("runtime", field, expected[field], actual[field], expected[field] == actual[field])
    end
  end

  defp protocol_rows(actual, expected) do
    expected
    |> Map.values()
    |> Enum.sort_by(& &1["id"])
    |> Enum.map(fn requirement ->
      provided = Map.get(actual, requirement["id"])
      actual_version = if provided, do: provided["version"], else: "missing"

      row(
        "protocol",
        requirement["id"],
        requirement["version"],
        actual_version,
        actual_version == requirement["version"]
      )
    end)
  end

  defp feature_rows(actual, expected) do
    Enum.map(expected, fn id ->
      provided = Map.get(actual, id)
      state = if provided, do: provided["state"], else: "missing"
      reason = if provided, do: provided["reason"], else: "feature is not declared by profile"
      row("feature", id, "supported", state, state == "supported", reason)
    end)
  end

  defp row(kind, subject, expected, actual, compatible, reason \\ nil) do
    %{
      "kind" => kind,
      "subject" => subject,
      "expected" => expected,
      "actual" => actual,
      "compatible" => compatible,
      "reason" => reason || if(compatible, do: "exact match", else: "exact value mismatch")
    }
  end

  defp violation(row),
    do: Map.take(row, ~w(kind subject expected actual reason))
end
