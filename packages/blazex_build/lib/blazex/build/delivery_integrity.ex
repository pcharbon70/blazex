defmodule BlazeX.Build.DeliveryIntegrity do
  @moduledoc "Deterministic SHA-384 SRI and Cache-Control manifest decoration."

  alias BlazeX.Build.{DeliveryIntegrityPolicy, JSON}

  def apply!(manifest, output, %DeliveryIntegrityPolicy{} = policy)
      when is_map(manifest) and is_binary(output) do
    artifacts = Map.fetch!(manifest, "artifacts")

    unless is_list(artifacts) and artifacts != [] and
             length(artifacts) <= policy.limits["max_artifacts"],
           do: invalid!("artifact count is outside policy bounds")

    paths = Enum.map(artifacts, &Map.get(&1, "path"))

    unless Enum.all?(paths, &is_binary/1) and length(paths) == length(Enum.uniq(paths)),
      do: invalid!("artifact paths are missing or duplicate")

    role_counts = Enum.frequencies_by(artifacts, &Map.get(&1, "role"))
    validate_roles!(role_counts, policy)

    decorated =
      Enum.map(artifacts, fn artifact ->
        role = Map.fetch!(artifact, "role")
        path = Map.fetch!(artifact, "path")
        source = artifact_path!(output, path)
        bytes = File.read!(source)

        unless byte_size(bytes) == Map.fetch!(artifact, "bytes") and
                 sha256(bytes) == Map.fetch!(artifact, "sha256"),
               do: invalid!("artifact identity drift: #{path}")

        artifact
        |> Map.put("integrity", "sha384-" <> sha384(bytes))
        |> Map.put("cache_control", policy.roles[role]["cache_control"])
      end)

    total = Enum.reduce(decorated, 0, &(Map.fetch!(&1, "bytes") + &2))

    if total > policy.limits["max_total_bytes"],
      do: invalid!("artifact bytes exceed policy limit")

    Map.merge(manifest, %{
      "artifacts" => decorated,
      "delivery_integrity" => %{
        "algorithm" => policy.algorithm,
        "manifest_cache_control" => "no-store",
        "policy_id" => policy.id,
        "policy_sha256" => canonical_sha256(policy.canonical)
      }
    })
  end

  def verify!(manifest, output, %DeliveryIntegrityPolicy{} = policy) do
    expected = apply!(Map.drop(manifest, ["delivery_integrity"]), output, policy)

    unless expected == manifest,
      do: invalid!("delivery integrity metadata drift")

    :ok
  end

  defp validate_roles!(counts, policy) do
    unknown = Map.keys(counts) -- Map.keys(policy.roles)
    unused = Map.keys(policy.roles) -- Map.keys(counts)

    unless unknown == [] and unused == [],
      do: invalid!("artifact roles are unknown or unused")

    Enum.each(policy.roles, fn {role, declaration} ->
      count = Map.fetch!(counts, role)

      unless count == 1 or
               (declaration["cardinality"] == "one-or-more" and count >= 1),
             do: invalid!("artifact role cardinality is invalid: #{role}")
    end)
  end

  defp artifact_path!(output, relative) do
    unless Path.type(relative) == :relative and relative != "" and
             Enum.all?(Path.split(relative), &(&1 not in ["", ".", ".."])),
           do: invalid!("artifact path escapes output")

    path = Path.join(Path.expand(output), relative)
    unless File.regular?(path), do: invalid!("artifact is missing: #{relative}")
    path
  end

  defp canonical_sha256(value), do: value |> JSON.encode!() |> then(&sha256(&1 <> "\n"))
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  defp sha384(bytes), do: :crypto.hash(:sha384, bytes) |> Base.encode64()
  defp invalid!(message), do: raise(ArgumentError, "delivery integrity #{message}")
end
