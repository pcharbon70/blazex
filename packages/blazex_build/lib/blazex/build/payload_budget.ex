defmodule BlazeX.Build.PayloadBudget do
  @moduledoc "Deterministic decoded/Brotli accounting and payload-budget decisions."

  alias BlazeX.Build.{JSON, PayloadPolicy}

  def measure!(manifest, root, %PayloadPolicy{} = policy, compressor)
      when is_map(manifest) and is_binary(root) and is_function(compressor, 2) do
    root = Path.expand(root)
    artifacts = manifest["artifacts"]

    unless is_list(artifacts) and length(artifacts) <= policy.limits["max_artifacts"],
      do: invalid!("manifest artifact count is invalid")

    declared = [
      manifest_row!(root, "build-manifest.json", "build-manifest", policy)
      | Enum.map(artifacts, &artifact_row!(root, &1, policy))
    ]

    paths = Enum.map(declared, & &1.path)

    if length(paths) != length(Enum.uniq(paths)),
      do: invalid!("manifest artifact paths are duplicate")

    exact_tree!(root, paths)

    public = Enum.filter(declared, &(&1.exposure == "public"))
    public_bytes = Enum.sum(Enum.map(public, &byte_size(&1.bytes)))

    if public_bytes > policy.limits["max_public_bytes"],
      do: invalid!("public payload exceeds accounting bound")

    measured =
      Enum.map(public, &measure_row!(&1, root, policy, compressor)) |> Enum.sort_by(& &1["path"])

    totals = totals(measured)

    source_map_bytes =
      measured
      |> Enum.filter(&String.ends_with?(&1["path"], ".map"))
      |> Enum.sum_by(& &1["decoded_bytes"])

    decisions = Enum.map(policy.budgets, &budget(&1, totals, source_map_bytes))
    failed = Enum.count(decisions, &(&1["result"] == "failed"))

    %{
      "schema_version" => "1.0.0",
      "policy_id" => policy.id,
      "policy_sha256" => digest_bytes(JSON.encode!(policy.canonical) <> "\n"),
      "complete" => true,
      "decision" => if(failed == 0, do: "accept", else: "reject"),
      "compression" => policy.compression,
      "artifacts" => measured,
      "totals" => totals,
      "budgets" => decisions,
      "summary" => %{
        "manifest_artifacts" => length(artifacts),
        "public_artifacts" => length(public),
        "private_artifacts" => length(declared) - length(public),
        "public_decoded_bytes" => public_bytes,
        "public_brotli_bytes" => Enum.sum_by(measured, & &1["brotli_bytes"]),
        "public_source_maps" => Enum.count(measured, &String.ends_with?(&1["path"], ".map")),
        "failed_budgets" => failed
      }
    }
  end

  def measure!(_, _, _, _), do: invalid!("payload measurement inputs are invalid")

  def node_brotli_samples!(path, %{"quality" => quality, "repetitions" => repetitions}) do
    executable = System.find_executable("node") || invalid!("node executable is unavailable")
    script = Path.expand("../../../priv/brotli_samples.mjs", __DIR__)

    case System.cmd(
           executable,
           [script, path, Integer.to_string(quality), Integer.to_string(repetitions)],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.map(fn line ->
          case Base.decode64(line) do
            {:ok, bytes} -> bytes
            :error -> invalid!("brotli helper returned malformed output")
          end
        end)

      {_output, _status} ->
        invalid!("brotli helper failed")
    end
  end

  defp manifest_row!(root, path, role, policy), do: row!(root, path, role, nil, policy)

  defp artifact_row!(root, artifact, policy) when is_map(artifact) do
    row!(root, artifact["path"], artifact["role"], artifact, policy)
  end

  defp artifact_row!(_, _, _), do: invalid!("manifest artifact is malformed")

  defp row!(root, path, role, artifact, policy) do
    validate_relative!(path)

    declaration =
      Map.get(policy.roles, role) || invalid!("manifest role is not classified: #{inspect(role)}")

    full = Path.join(root, path)
    unless File.regular?(full), do: invalid!("manifest artifact is missing: #{path}")
    bytes = File.read!(full)
    hash = digest_bytes(bytes)

    if artifact && (artifact["bytes"] != byte_size(bytes) or artifact["sha256"] != hash),
      do: invalid!("manifest artifact identity drift: #{path}")

    if artifact && artifact["exposure"] != declaration["exposure"],
      do: invalid!("manifest artifact exposure drift: #{path}")

    %{
      path: path,
      role: role,
      owner: declaration["owner"],
      exposure: declaration["exposure"],
      bytes: bytes,
      sha256: hash
    }
  end

  defp exact_tree!(root, paths) do
    found =
      root
      |> Path.join("**/*")
      |> Path.wildcard()
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&Path.relative_to(&1, root))
      |> Enum.sort()

    if found != Enum.sort(paths), do: invalid!("build tree contains missing or undeclared files")
  end

  defp measure_row!(row, root, policy, compressor) do
    samples = compressor.(Path.join(root, row.path), policy.compression)
    expected = policy.compression["repetitions"]

    unless is_list(samples) and length(samples) == expected and Enum.all?(samples, &is_binary/1),
      do: invalid!("compressor returned an invalid sample set: #{row.path}")

    unless length(Enum.uniq(samples)) == 1,
      do: invalid!("brotli output is nondeterministic: #{row.path}")

    compressed = hd(samples)
    File.write!(Path.join(root, row.path <> ".br"), compressed, [:exclusive])

    %{
      "path" => row.path,
      "role" => row.role,
      "owner" => row.owner,
      "exposure" => row.exposure,
      "decoded_bytes" => byte_size(row.bytes),
      "source_sha256" => row.sha256,
      "brotli_bytes" => byte_size(compressed),
      "brotli_sha256" => digest_bytes(compressed)
    }
  end

  defp totals(rows) do
    rows
    |> Enum.group_by(& &1["owner"])
    |> Map.new(fn {owner, owned} ->
      {owner,
       %{
         "decoded_bytes" => Enum.sum_by(owned, & &1["decoded_bytes"]),
         "brotli_bytes" => Enum.sum_by(owned, & &1["brotli_bytes"]),
         "artifacts" => length(owned)
       }}
    end)
  end

  defp budget(spec, totals, source_map_bytes) do
    observed =
      if spec["metric"] == "source_map_bytes",
        do: source_map_bytes,
        else: get_in(totals, [spec["owner"], spec["metric"]]) || 0

    passed =
      case spec["direction"] do
        "at-most" -> observed <= spec["threshold"]
        "exactly" -> observed == spec["threshold"]
      end

    Map.merge(spec, %{
      "observed" => observed,
      "result" => if(passed, do: "passed", else: "failed")
    })
  end

  defp validate_relative!(path) do
    unless is_binary(path) and path != "" and Path.type(path) == :relative and
             Enum.all?(Path.split(path), &(&1 not in ["", ".", ".."])),
           do: invalid!("artifact path is invalid")
  end

  defp digest_bytes(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  defp invalid!(message), do: raise(ArgumentError, message)
end
