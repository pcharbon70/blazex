defmodule BlazeXBrowserPhoenix.StaticDeliveryTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  @endpoint BlazeXBrowserPhoenix.Endpoint

  setup do
    :ok = BlazeXBrowserPhoenix.StaticDeliveryCache.reset()

    root =
      Path.join(System.tmp_dir!(), "blazex-bh07-profile-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(root, "evidence"))
    File.write!(Path.join(root, "index.html"), "<!doctype html><title>BH-07</title>\n")
    File.write!(Path.join(root, "evidence/private.json"), "{}\n")

    artifacts = [
      artifact(root, "index.html", "public", "text/html", "document"),
      artifact(
        root,
        "evidence/private.json",
        "private-build-evidence",
        "application/json",
        "secret-audit-report"
      )
    ]

    manifest = %{
      "artifacts" => artifacts,
      "entrypoint" => %{"id" => "counter", "module" => "Elixir.BlazeX.Counter"},
      "manifest_id" => "blazex.bh06.browser-slice/1",
      "schema_version" => "1.0.0",
      "support_state" => "unsupported-development-evidence"
    }

    manifest_bytes = canonical_json(manifest) <> "\n"
    manifest_path = Path.join(root, "build-manifest.json")
    attestation_path = Path.join(root, "entrypoint-attestation.json")

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

    File.write!(manifest_path, manifest_bytes)
    File.write!(attestation_path, Jason.encode!(attestation))
    previous_root = Application.get_env(:blazex_browser_phoenix, :bh07_static_root)
    previous_attestation = Application.get_env(:blazex_browser_phoenix, :bh07_attestation_path)
    Application.put_env(:blazex_browser_phoenix, :bh07_static_root, root)
    Application.put_env(:blazex_browser_phoenix, :bh07_attestation_path, attestation_path)

    on_exit(fn ->
      restore_env(:bh07_static_root, previous_root)
      restore_env(:bh07_attestation_path, previous_attestation)
      File.rm_rf!(root)
    end)

    %{root: root, manifest_bytes: manifest_bytes}
  end

  test "serves the attested document, manifest, HEAD, and conditional response", context do
    document = request(:get, "/bh07/")
    assert document.status == 200
    assert document.resp_body == "<!doctype html><title>BH-07</title>\n"
    assert get_resp_header(document, "content-type") == ["text/html"]
    assert get_resp_header(document, "cache-control") == ["no-store"]
    assert get_resp_header(document, "x-content-type-options") == ["nosniff"]
    [etag] = get_resp_header(document, "etag")

    head = request(:head, "/bh07/")
    assert head.status == 200
    assert head.resp_body == ""
    assert get_resp_header(head, "etag") == [etag]
    assert get_resp_header(head, "content-length") == ["36"]

    unchanged = request(:get, "/bh07/", [{"if-none-match", etag}])
    assert unchanged.status == 304
    assert unchanged.resp_body == ""

    manifest = request(:get, "/bh07/build-manifest.json")
    assert manifest.status == 200
    assert manifest.resp_body == context.manifest_bytes
    assert get_resp_header(manifest, "content-type") == ["application/json"]

    assert BlazeXBrowserPhoenix.StaticDeliveryCache.snapshot() == %{validations: 1, hits: 3}
  end

  test "redirects the route root and rejects private, undeclared, and unsupported requests" do
    redirect = request(:get, "/bh07")
    assert redirect.status == 308
    assert get_resp_header(redirect, "location") == ["/bh07/"]

    assert request(:get, "/bh07/evidence/private.json").status == 404
    assert request(:get, "/bh07/undeclared.js").status == 404
    assert request(:post, "/bh07/").status == 405
  end

  test "fails closed when an artifact changes after attestation", context do
    File.write!(Path.join(context.root, "index.html"), "changed\n")
    assert request(:get, "/bh07/").status == 404
  end

  test "revalidates once when the manifest identity changes", context do
    assert request(:get, "/bh07/").status == 200
    assert %{validations: 1} = BlazeXBrowserPhoenix.StaticDeliveryCache.snapshot()

    bytes =
      String.replace(context.manifest_bytes, "Elixir.BlazeX.Counter", "Elixir.BlazeX.Counter2")

    File.write!(Path.join(context.root, "build-manifest.json"), bytes)
    assert request(:get, "/bh07/").status == 404
    assert request(:get, "/bh07/").status == 404
    assert %{validations: 2, hits: 1} = BlazeXBrowserPhoenix.StaticDeliveryCache.snapshot()
  end

  defp request(method, path, headers \\ []) do
    conn =
      Enum.reduce(headers, conn(method, path), fn {name, value}, acc ->
        put_req_header(acc, name, value)
      end)

    @endpoint.call(conn, @endpoint.init([]))
  end

  defp artifact(root, path, exposure, media_type, role) do
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
      "role" => role,
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

  defp restore_env(key, nil), do: Application.delete_env(:blazex_browser_phoenix, key)
  defp restore_env(key, value), do: Application.put_env(:blazex_browser_phoenix, key, value)
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
