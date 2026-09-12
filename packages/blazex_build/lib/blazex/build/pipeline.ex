defmodule BlazeX.Build.Pipeline do
  @moduledoc "Deterministic, content-addressed BH-06 candidate asset assembly."

  alias BlazeX.Build.{EntryPoint, JSON}
  @manifest "build-manifest.json"
  @assets [
    {:runtime_module, "runtime-module", ".mjs", "text/javascript"},
    {:runtime_wasm, "runtime-wasm", ".wasm", "application/wasm"},
    {:bundle, "application-bundle", ".avm", "application/vnd.atomvm.avm"},
    {:host, "browser-host", ".js", "text/javascript"}
  ]

  def build!(%EntryPoint{} = spec, output, options \\ []) when is_binary(output) do
    output = Path.expand(output)
    ensure_empty!(output)
    File.mkdir_p!(Path.join(output, "assets"))
    immutable = Enum.map(@assets, &copy_asset!(spec, output, &1))
    host = Enum.find(immutable, &(&1["role"] == "browser-host"))
    document = build_document!(spec.document, output, host["path"])

    artifacts =
      [document | immutable] ++
        report_artifact!(options, output, :reachability, "reachability-report") ++
        report_artifact!(options, output, :client_safety, "client-safety-report")

    manifest = %{
      "schema_version" => "1.0.0",
      "manifest_id" => "blazex.bh06.browser-slice/1",
      "support_state" => "unsupported-development-evidence",
      "entrypoint" => %{"id" => spec.id, "module" => spec.module},
      "compatibility" => spec.compatibility,
      "artifacts" => artifacts
    }

    File.write!(Path.join(output, @manifest), JSON.encode!(manifest) <> "\n", [:exclusive])
    verify!(output)
    manifest
  end

  def verify!(output) when is_binary(output) do
    output = Path.expand(output)
    manifest = File.read!(Path.join(output, @manifest))
    paths = Regex.scan(~r/"path":"([^"]+)"/, manifest, capture: :all_but_first) |> List.flatten()

    hashes =
      Regex.scan(~r/"sha256":"([0-9a-f]{64})"/, manifest, capture: :all_but_first)
      |> List.flatten()

    if paths == [] or length(paths) != length(hashes) or
         length(paths) != length(Enum.uniq(paths)),
       do: raise(ArgumentError, "manifest artifact records are missing, duplicate, or malformed")

    Enum.zip(paths, hashes)
    |> Enum.each(fn {relative, expected} ->
      validate_relative!(relative)
      path = Path.join(output, relative)

      unless File.regular?(path),
        do: raise(ArgumentError, "manifest asset is missing: #{relative}")

      unless digest(path) == expected,
        do: raise(ArgumentError, "manifest integrity mismatch: #{relative}")
    end)

    :ok
  end

  defp copy_asset!(spec, output, {field, role, extension, media_type}) do
    source = Map.fetch!(spec, field)
    hash = digest(source)
    relative = "assets/#{role}-#{hash}#{extension}"
    File.cp!(source, Path.join(output, relative))
    record(relative, role, media_type, hash, File.stat!(source).size, "immutable")
  end

  defp build_document!(source, output, host_path) do
    body = File.read!(source)

    unless String.contains?(body, "{{HOST_ASSET}}"),
      do: raise(ArgumentError, "document must contain the {{HOST_ASSET}} placeholder")

    body = String.replace(body, "{{HOST_ASSET}}", host_path)
    target = Path.join(output, "index.html")
    File.write!(target, body, [:exclusive])
    record("index.html", "document", "text/html", digest(target), byte_size(body), "no-store")
  end

  defp report_artifact!(options, output, option, role) do
    case Keyword.get(options, option) do
      nil ->
        []

      report when is_map(report) ->
        body = JSON.encode!(report) <> "\n"
        hash = digest_bytes(body)
        relative = "assets/#{role}-#{hash}.json"
        File.write!(Path.join(output, relative), body, [:exclusive])

        [
          record(
            relative,
            role,
            "application/json",
            hash,
            byte_size(body),
            "immutable"
          )
        ]

      _ ->
        raise ArgumentError, "#{String.replace(role, "-", " ")} must be a map"
    end
  end

  defp record(path, role, media_type, hash, bytes, cache),
    do: %{
      "path" => path,
      "role" => role,
      "media_type" => media_type,
      "sha256" => hash,
      "bytes" => bytes,
      "cache" => cache
    }

  defp ensure_empty!(output) do
    case File.ls(output) do
      {:error, :enoent} -> :ok
      {:ok, []} -> :ok
      {:ok, _} -> raise(ArgumentError, "build output must be absent or empty")
      {:error, reason} -> raise(File.Error, reason: reason, action: "inspect", path: output)
    end
  end

  defp validate_relative!(path) do
    if Path.type(path) != :relative or path == "" or
         Enum.any?(Path.split(path), &(&1 in ["", ".", ".."])),
       do: raise(ArgumentError, "manifest asset path escapes output: #{inspect(path)}")
  end

  defp digest(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
  defp digest_bytes(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
