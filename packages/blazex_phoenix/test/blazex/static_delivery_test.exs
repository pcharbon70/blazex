defmodule BlazeX.Phoenix.StaticDeliveryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Phoenix.StaticDelivery

  setup do
    root = Path.join(System.tmp_dir!(), "blazex-static-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, "assets"))
    File.mkdir_p!(Path.join(root, "evidence"))
    File.write!(Path.join(root, "assets/app-deadbeef.js"), "console.log('attested');\n")
    File.write!(Path.join(root, "evidence/private.json"), "{}\n")

    artifacts = [
      artifact(root, "assets/app-deadbeef.js", "public", "text/javascript"),
      artifact(root, "evidence/private.json", "private-build-evidence", "application/json")
    ]

    manifest = %{
      "artifacts" => artifacts,
      "entrypoint" => %{"id" => "counter", "module" => "Elixir.BlazeX.Counter"},
      "manifest_id" => "blazex.bh06.browser-slice/1",
      "schema_version" => "1.0.0",
      "support_state" => "unsupported-development-evidence"
    }

    manifest_bytes = canonical_json(manifest) <> "\n"

    attestation = %{
      "artifacts" => Enum.map(artifacts, &attested_artifact/1),
      "decision" => "accept",
      "entrypoint" => manifest["entrypoint"],
      "manifest" => %{
        "id" => manifest["manifest_id"],
        "sha256" => sha256(manifest_bytes),
        "support_state" => manifest["support_state"]
      },
      "policy_id" => "blazex.bh06.entrypoint-accounting/1",
      "schema_version" => "1.0.0"
    }

    on_exit(fn -> File.rm_rf!(root) end)

    %{root: root, manifest: manifest, manifest_bytes: manifest_bytes, attestation: attestation}
  end

  test "resolves only attested public artifacts with exact delivery metadata", context do
    delivery = delivery(context)

    assert {:ok, asset} = StaticDelivery.resolve(delivery, "GET", "/assets/app-deadbeef.js")
    assert asset.body == "console.log('attested');\n"
    assert asset.bytes == byte_size(asset.body)
    assert asset.media_type == "text/javascript"
    assert asset.cache_control == "public, max-age=31536000, immutable"
    assert asset.etag == ~s("sha256-#{sha256(asset.body)}")
    assert String.starts_with?(asset.integrity, "sha384-")

    assert {:ok, manifest} = StaticDelivery.resolve(delivery, "HEAD", "build-manifest.json")
    assert manifest.body == context.manifest_bytes
    assert manifest.cache_control == "no-store"
    assert manifest.media_type == "application/json"
  end

  test "defaults the route root to index.html", context do
    index_body = "<!doctype html>\n"
    File.write!(Path.join(context.root, "index.html"), index_body)
    index = artifact(context.root, "index.html", "public", "text/html")
    manifest = %{context.manifest | "artifacts" => [index | context.manifest["artifacts"]]}
    bytes = canonical_json(manifest) <> "\n"

    attestation = %{
      context.attestation
      | "artifacts" => Enum.map(manifest["artifacts"], &attested_artifact/1),
        "manifest" => %{context.attestation["manifest"] | "sha256" => sha256(bytes)}
    }

    delivery = StaticDelivery.new!(context.root, manifest, attestation, bytes)

    assert {:ok, %{body: ^index_body, cache_control: "no-store"}} =
             StaticDelivery.resolve(delivery, "GET", "/")
  end

  test "rejects private, undeclared, traversal, and unsupported requests", context do
    delivery = delivery(context)

    assert {:error, :not_found} = StaticDelivery.resolve(delivery, "GET", "evidence/private.json")
    assert {:error, :not_found} = StaticDelivery.resolve(delivery, "GET", "undeclared.js")
    assert {:error, :invalid_path} = StaticDelivery.resolve(delivery, "GET", "../secret")

    assert {:error, :method_not_allowed} =
             StaticDelivery.resolve(delivery, "POST", "assets/app-deadbeef.js")
  end

  test "rejects a non-accepting or stale attestation", context do
    rejected = %{context.attestation | "decision" => "reject"}

    assert_raise ArgumentError, "decision-mismatch", fn ->
      StaticDelivery.new!(context.root, context.manifest, rejected, context.manifest_bytes)
    end

    stale = %{
      context.attestation
      | "manifest" => %{context.attestation["manifest"] | "sha256" => String.duplicate("0", 64)}
    }

    assert_raise ArgumentError, "sha256-mismatch", fn ->
      StaticDelivery.new!(context.root, context.manifest, stale, context.manifest_bytes)
    end
  end

  test "rejects canonicalization, inventory, cache, and content changes", context do
    assert_raise ArgumentError, "manifest-not-canonical", fn ->
      StaticDelivery.new!(
        context.root,
        context.manifest,
        context.attestation,
        context.manifest_bytes <> " "
      )
    end

    [first | rest] = context.manifest["artifacts"]
    duplicate = %{context.manifest | "artifacts" => [first, first | rest]}

    duplicate_bytes = canonical_json(duplicate) <> "\n"

    duplicate_attestation = %{
      context.attestation
      | "manifest" => %{context.attestation["manifest"] | "sha256" => sha256(duplicate_bytes)}
    }

    assert_raise ArgumentError, "artifact-path-duplicate", fn ->
      StaticDelivery.new!(context.root, duplicate, duplicate_attestation, duplicate_bytes)
    end

    [public, private] = context.manifest["artifacts"]
    wrong_cache = %{public | "cache_control" => "no-store"}
    changed = %{context.manifest | "artifacts" => [wrong_cache, private]}
    changed_bytes = canonical_json(changed) <> "\n"

    changed_attestation = %{
      context.attestation
      | "artifacts" => Enum.map(changed["artifacts"], &attested_artifact/1),
        "manifest" => %{context.attestation["manifest"] | "sha256" => sha256(changed_bytes)}
    }

    assert_raise ArgumentError, "artifact-cache-invalid", fn ->
      StaticDelivery.new!(context.root, changed, changed_attestation, changed_bytes)
    end

    delivery = delivery(context)
    File.write!(Path.join(context.root, "assets/app-deadbeef.js"), "changed\n")

    assert {:error, :artifact_changed} =
             StaticDelivery.resolve(delivery, "GET", "assets/app-deadbeef.js")
  end

  defp delivery(context) do
    StaticDelivery.new!(
      context.root,
      context.manifest,
      context.attestation,
      context.manifest_bytes
    )
  end

  defp artifact(root, path, exposure, media_type) do
    body = File.read!(Path.join(root, path))

    %{
      "bytes" => byte_size(body),
      "cache_control" =>
        if(exposure == "public" and path != "index.html",
          do: "public, max-age=31536000, immutable",
          else: "no-store"
        ),
      "exposure" => exposure,
      "integrity" => "sha384-" <> Base.encode64(:crypto.hash(:sha384, body)),
      "media_type" => media_type,
      "path" => path,
      "role" => if(exposure == "public", do: "browser-host", else: "secret-audit-report"),
      "sha256" => sha256(body)
    }
  end

  defp attested_artifact(artifact) do
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
  end

  defp sha256(body), do: Base.encode16(:crypto.hash(:sha256, body), case: :lower)

  defp canonical_json(value) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map_join(",", fn {key, item} -> canonical_json(key) <> ":" <> canonical_json(item) end)
    |> then(&("{" <> &1 <> "}"))
  end

  defp canonical_json(value) when is_list(value),
    do: "[" <> Enum.map_join(value, ",", &canonical_json/1) <> "]"

  defp canonical_json(value) when is_binary(value), do: inspect(value)
  defp canonical_json(value) when is_integer(value), do: Integer.to_string(value)
end
