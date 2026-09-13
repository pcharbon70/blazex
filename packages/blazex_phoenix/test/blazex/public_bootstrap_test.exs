defmodule BlazeX.Phoenix.PublicBootstrapTest do
  use ExUnit.Case, async: true

  alias BlazeX.Phoenix.PublicBootstrap
  alias BlazeX.Phoenix.StaticDelivery

  setup do
    root = Path.join(System.tmp_dir!(), "blazex-bootstrap-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    File.write!(Path.join(root, "index.html"), "<!doctype html>\n")
    artifact = artifact(root, "index.html")

    manifest = %{
      "artifacts" => [artifact],
      "entrypoint" => %{"id" => "counter", "module" => "Elixir.BlazeX.Counter"},
      "manifest_id" => "blazex.bh06.browser-slice/1",
      "schema_version" => "1.0.0",
      "support_state" => "unsupported-development-evidence"
    }

    manifest_bytes = canonical_json(manifest) <> "\n"

    attestation = %{
      "artifacts" => [Map.drop(artifact, ["cache", "media_type"])],
      "attestation_id" => "blazex.bh06.entrypoint-accounting/1/counter",
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

    delivery = StaticDelivery.new!(root, manifest, attestation, manifest_bytes)
    on_exit(fn -> File.rm_rf!(root) end)
    %{delivery: delivery, manifest_bytes: manifest_bytes}
  end

  test "builds deterministic public bootstrap bound to delivery identity", context do
    first = PublicBootstrap.build!(context.delivery)
    second = PublicBootstrap.build!(context.delivery)

    assert first == second
    assert first.bytes == byte_size(first.body)
    assert first.etag == ~s("sha256-#{sha256(first.body)}")
    assert String.ends_with?(first.body, "\n")
    assert first.document["protocol"] == "blazex.bh07.bootstrap/1"
    assert first.document["trust"] == "public-untrusted-no-server-authority"

    assert first.document["manifest"] == %{
             "id" => "blazex.bh06.browser-slice/1",
             "sha256" => sha256(context.manifest_bytes),
             "url" => "/bh07/build-manifest.json"
           }

    assert first.document["attestation"] == %{
             "id" => "blazex.bh06.entrypoint-accounting/1/counter"
           }
  end

  test "retains bounded JSON-compatible public state", context do
    state = %{
      "locale" => "fr-CA",
      "feature_flags" => %{"compact" => true},
      "items" => [1, nil, false, "λ"]
    }

    assert PublicBootstrap.build!(context.delivery, state).document["public_state"] == state
  end

  test "capability declaration denies server authority", context do
    capabilities = PublicBootstrap.build!(context.delivery).document["capabilities"]
    assert capabilities["static_delivery"]
    assert capabilities["browser_local_execution"]
    assert capabilities["command_admission"]
    assert capabilities["trusted_command_execution"]
    assert capabilities["sessions"]
    assert capabilities["authentication_projection"]
    assert capabilities["csrf_protection"]
    assert capabilities["remote_commands"]
    assert capabilities["pushes"]
    assert capabilities["server_push"]
    assert capabilities["server_mutation"]
  end

  test "rejects secret-like and authority-bearing keys at every depth", context do
    for key <- [
          "api_token",
          "password",
          "cookie_value",
          "session_id",
          "csrf",
          "user_role",
          "permissions",
          "authorization",
          "authenticated",
          "identity",
          "principal",
          "user_id",
          "allowed_actions",
          "command_url",
          "idempotency_key",
          "private_key"
        ] do
      assert_raise ArgumentError, "bootstrap-key-invalid", fn ->
        PublicBootstrap.build!(context.delivery, %{"safe" => %{key => "value"}})
      end
    end
  end

  test "rejects invalid keys, values, ranges, width, and depth", context do
    invalid = [
      %{unsafe: "atom-key"},
      %{"Upper" => "value"},
      %{"value" => :atom},
      %{"value" => 1.5},
      %{"value" => 9_007_199_254_740_992},
      %{"value" => String.duplicate("x", 257)},
      %{"value" => Enum.to_list(1..33)},
      %{"value" => %{"a" => %{"b" => %{"c" => %{"d" => %{}}}}}}
    ]

    for value <- invalid do
      assert_raise ArgumentError, fn -> PublicBootstrap.build!(context.delivery, value) end
    end
  end

  test "rejects node and encoded document amplification", context do
    subtree = Map.new(1..16, &{"v#{&1}", Enum.to_list(1..16)})

    assert_raise ArgumentError, "bootstrap-node-limit-exceeded", fn ->
      PublicBootstrap.build!(context.delivery, %{"tree" => subtree})
    end

    oversized = Map.new(1..20, &{"field#{&1}", String.duplicate("x", 256)})

    assert_raise ArgumentError, "bootstrap-document-too-large", fn ->
      PublicBootstrap.build!(context.delivery, oversized)
    end
  end

  test "rejects invalid asset bases and stale attestation identity", context do
    for base <- [
          "bh07/",
          "/bh07",
          "//attacker.invalid/",
          "https://attacker.invalid/",
          "/bh07/../private/",
          "/bh07/?query"
        ] do
      assert_raise ArgumentError, "bootstrap-asset-base-invalid", fn ->
        PublicBootstrap.build!(context.delivery, %{}, base)
      end
    end

    stale = %{
      context.delivery
      | attestation: %{context.delivery.attestation | "attestation_id" => "stale"}
    }

    assert_raise ArgumentError, "bootstrap-delivery-identity-invalid", fn ->
      PublicBootstrap.build!(stale)
    end
  end

  defp artifact(root, path) do
    body = File.read!(Path.join(root, path))

    %{
      "bytes" => byte_size(body),
      "cache" => "no-store",
      "cache_control" => "no-store",
      "exposure" => "public",
      "integrity" => "sha384-" <> Base.encode64(:crypto.hash(:sha384, body)),
      "media_type" => "text/html",
      "path" => path,
      "role" => "document",
      "sha256" => sha256(body)
    }
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
