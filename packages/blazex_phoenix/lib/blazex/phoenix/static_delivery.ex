defmodule BlazeX.Phoenix.StaticDelivery do
  @moduledoc """
  Validates and resolves an accepted BH-06 browser artifact set.

  This boundary is independent of Plug and Phoenix. A host adapter supplies
  decoded manifest and attestation documents plus the exact manifest bytes.
  Construction validates the entire inventory; resolution exposes only public
  files and the manifest itself.
  """

  @manifest_path "build-manifest.json"
  @max_manifest_bytes 1_048_576
  @max_artifacts 256
  @max_artifact_bytes 134_217_728
  @allowed_methods ["GET", "HEAD"]
  @hex64 ~r/\A[0-9a-f]{64}\z/
  @sri384 ~r/\Asha384-[A-Za-z0-9+\/]+={0,2}\z/

  @enforce_keys [:root, :manifest, :manifest_bytes, :public]
  defstruct [:root, :manifest, :manifest_bytes, :public]

  @type artifact :: %{required(String.t()) => term()}
  @type t :: %__MODULE__{
          root: String.t(),
          manifest: map(),
          manifest_bytes: binary(),
          public: %{required(String.t()) => artifact()}
        }

  @spec new!(Path.t(), map(), map(), binary() | nil) :: t()
  def new!(root, manifest, attestation, manifest_bytes \\ nil)
      when is_binary(root) and is_map(manifest) and is_map(attestation) do
    root = Path.expand(root)
    manifest_bytes = manifest_bytes || canonical_document(manifest)

    validate_manifest_bytes!(manifest, manifest_bytes)
    validate_attestation!(manifest, attestation, manifest_bytes)

    artifacts = require_list!(manifest, "artifacts")

    if length(artifacts) > @max_artifacts do
      raise ArgumentError, "artifact-count-exceeded"
    end

    paths = Enum.map(artifacts, &require_string!(&1, "path"))

    if length(paths) != MapSet.size(MapSet.new(paths)) do
      raise ArgumentError, "artifact-path-duplicate"
    end

    attested_by_path =
      attestation
      |> require_list!("artifacts")
      |> Map.new(fn artifact -> {require_string!(artifact, "path"), artifact} end)

    if MapSet.new(paths) != MapSet.new(Map.keys(attested_by_path)) do
      raise ArgumentError, "attested-inventory-mismatch"
    end

    public =
      Map.new(artifacts, fn artifact ->
        path = validate_artifact!(root, artifact, Map.fetch!(attested_by_path, artifact["path"]))
        {path, artifact}
      end)
      |> Map.reject(fn {_path, artifact} -> artifact["exposure"] != "public" end)
      |> Map.put(@manifest_path, manifest_artifact(manifest_bytes))

    %__MODULE__{root: root, manifest: manifest, manifest_bytes: manifest_bytes, public: public}
  end

  @spec resolve(t(), String.t(), String.t()) ::
          {:ok,
           %{
             path: Path.t(),
             bytes: non_neg_integer(),
             media_type: String.t(),
             cache_control: String.t(),
             etag: String.t(),
             integrity: String.t(),
             body: binary()
           }}
          | {:error, atom()}
  def resolve(%__MODULE__{} = delivery, method, request_path)
      when is_binary(method) and is_binary(request_path) do
    with true <- method in @allowed_methods,
         {:ok, normalized} <- normalize_request_path(request_path),
         {:ok, artifact} <- Map.fetch(delivery.public, normalized),
         {:ok, body} <- read(delivery, normalized),
         :ok <- verify_body(body, artifact) do
      {:ok,
       %{
         path:
           if(normalized == @manifest_path, do: nil, else: safe_join!(delivery.root, normalized)),
         body: body,
         bytes: artifact["bytes"],
         media_type: artifact["media_type"],
         cache_control: artifact["cache_control"],
         etag: ~s("sha256-#{artifact["sha256"]}"),
         integrity: artifact["integrity"]
       }}
    else
      false -> {:error, :method_not_allowed}
      :error -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def resolve(%__MODULE__{}, _method, _request_path), do: {:error, :invalid_request}

  defp validate_manifest_bytes!(manifest, bytes) do
    if byte_size(bytes) > @max_manifest_bytes, do: raise(ArgumentError, "manifest-too-large")
    if bytes != canonical_document(manifest), do: raise(ArgumentError, "manifest-not-canonical")
    require_equal!(manifest, "schema_version", "1.0.0")
    require_equal!(manifest, "manifest_id", "blazex.bh06.browser-slice/1")
    require_equal!(manifest, "support_state", "unsupported-development-evidence")
  end

  defp validate_attestation!(manifest, attestation, manifest_bytes) do
    require_equal!(attestation, "schema_version", "1.0.0")
    require_equal!(attestation, "decision", "accept")
    require_equal!(attestation, "policy_id", "blazex.bh06.entrypoint-accounting/1")

    binding = require_map!(attestation, "manifest")
    require_equal!(binding, "id", manifest["manifest_id"])
    require_equal!(binding, "support_state", manifest["support_state"])
    require_equal!(binding, "sha256", sha256(manifest_bytes))

    if attestation["entrypoint"] != manifest["entrypoint"] do
      raise ArgumentError, "entrypoint-mismatch"
    end
  end

  defp validate_artifact!(root, artifact, attested) when is_map(artifact) and is_map(attested) do
    path = require_string!(artifact, "path")
    absolute = safe_join!(root, path)
    exposure = require_string!(artifact, "exposure")

    unless exposure in ["public", "private-build-evidence"] do
      raise ArgumentError, "artifact-exposure-invalid"
    end

    expected_attestation =
      Map.take(artifact, [
        "bytes",
        "cache_control",
        "exposure",
        "feature_id",
        "integrity",
        "path",
        "role",
        "sha256"
      ])

    if attested != expected_attestation do
      raise ArgumentError, "artifact-attestation-mismatch"
    end

    bytes = require_non_negative_integer!(artifact, "bytes")
    if bytes > @max_artifact_bytes, do: raise(ArgumentError, "artifact-too-large")

    digest = require_string!(artifact, "sha256")
    integrity = require_string!(artifact, "integrity")
    media_type = require_string!(artifact, "media_type")
    cache_control = require_string!(artifact, "cache_control")

    unless Regex.match?(@hex64, digest), do: raise(ArgumentError, "artifact-sha256-invalid")

    unless Regex.match?(@sri384, integrity),
      do: raise(ArgumentError, "artifact-integrity-invalid")

    if media_type == "", do: raise(ArgumentError, "artifact-media-type-invalid")

    expected_cache =
      if exposure == "public" and path != "index.html",
        do: "public, max-age=31536000, immutable",
        else: "no-store"

    if cache_control != expected_cache, do: raise(ArgumentError, "artifact-cache-invalid")

    body = File.read!(absolute)
    verify_body!(body, artifact)
    path
  end

  defp validate_artifact!(_root, _artifact, _attested),
    do: raise(ArgumentError, "artifact-invalid")

  defp verify_body(body, artifact) do
    if byte_size(body) == artifact["bytes"] and sha256(body) == artifact["sha256"] and
         sri384(body) == artifact["integrity"] do
      :ok
    else
      {:error, :artifact_changed}
    end
  end

  defp verify_body!(body, artifact) do
    case verify_body(body, artifact) do
      :ok -> :ok
      {:error, _} -> raise ArgumentError, "artifact-content-mismatch"
    end
  end

  defp read(%__MODULE__{manifest_bytes: bytes}, @manifest_path), do: {:ok, bytes}

  defp read(%__MODULE__{root: root}, path) do
    case File.read(safe_join!(root, path)) do
      {:ok, body} -> {:ok, body}
      {:error, _} -> {:error, :artifact_unavailable}
    end
  end

  defp normalize_request_path(path) do
    path = String.trim_leading(path, "/")

    cond do
      path == "" -> {:ok, "index.html"}
      String.contains?(path, ["\\", "\0"]) -> {:error, :invalid_path}
      Path.type(path) != :relative -> {:error, :invalid_path}
      Enum.any?(Path.split(path), &(&1 in ["", ".", ".."])) -> {:error, :invalid_path}
      true -> {:ok, path}
    end
  end

  defp safe_join!(root, path) do
    case Path.safe_relative(path, root) do
      {:ok, relative} -> Path.join(root, relative)
      :error -> raise ArgumentError, "artifact-path-invalid"
    end
  end

  defp manifest_artifact(bytes) do
    %{
      "bytes" => byte_size(bytes),
      "cache_control" => "no-store",
      "exposure" => "public",
      "integrity" => sri384(bytes),
      "media_type" => "application/json",
      "path" => @manifest_path,
      "role" => "manifest",
      "sha256" => sha256(bytes)
    }
  end

  defp require_map!(map, key) do
    case map[key] do
      value when is_map(value) -> value
      _ -> raise ArgumentError, "#{key}-invalid"
    end
  end

  defp require_list!(map, key) do
    case map[key] do
      value when is_list(value) -> value
      _ -> raise ArgumentError, "#{key}-invalid"
    end
  end

  defp require_string!(map, key) do
    case map[key] do
      value when is_binary(value) and value != "" -> value
      _ -> raise ArgumentError, "#{key}-invalid"
    end
  end

  defp require_non_negative_integer!(map, key) do
    case map[key] do
      value when is_integer(value) and value >= 0 -> value
      _ -> raise ArgumentError, "#{key}-invalid"
    end
  end

  defp require_equal!(map, key, expected) do
    if map[key] != expected, do: raise(ArgumentError, "#{key}-mismatch")
  end

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)
  defp sri384(bytes), do: "sha384-" <> Base.encode64(:crypto.hash(:sha384, bytes))
  defp canonical_document(value), do: canonical_json(value) <> "\n"

  defp canonical_json(value) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map_join(",", fn {key, item} -> canonical_json(key) <> ":" <> canonical_json(item) end)
    |> then(&("{" <> &1 <> "}"))
  end

  defp canonical_json(value) when is_list(value),
    do: "[" <> Enum.map_join(value, ",", &canonical_json/1) <> "]"

  defp canonical_json(value) when is_binary(value) do
    escaped =
      value
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\b", "\\b")
      |> String.replace("\f", "\\f")
      |> String.replace("\n", "\\n")
      |> String.replace("\r", "\\r")
      |> String.replace("\t", "\\t")

    "\"" <> escaped <> "\""
  end

  defp canonical_json(value) when is_integer(value), do: Integer.to_string(value)
  defp canonical_json(true), do: "true"
  defp canonical_json(false), do: "false"
  defp canonical_json(nil), do: "null"
end
