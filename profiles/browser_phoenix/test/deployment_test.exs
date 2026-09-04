defmodule BlazeXBrowserPhoenix.DeploymentTest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  @endpoint BlazeXBrowserPhoenix.Endpoint

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "blazex-bh01-deployment-test-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(Path.join(root, "artifacts"))
    File.write!(Path.join(root, "index.html"), "<!doctype html><title>fallback</title>")
    File.write!(Path.join(root, "runtime-manifest.json"), ~s({"schema_version":"1.0.0"}))
    File.write!(Path.join(root, "artifacts/runtime.wasm"), <<0, 97, 115, 109, 1, 0, 0, 0>>)
    previous = Application.get_env(:blazex_browser_phoenix, :static_root)
    Application.put_env(:blazex_browser_phoenix, :static_root, root)

    on_exit(fn ->
      File.rm_rf!(root)

      if previous,
        do: Application.put_env(:blazex_browser_phoenix, :static_root, previous),
        else: Application.delete_env(:blazex_browser_phoenix, :static_root)
    end)

    :ok
  end

  test "serves volatile manifest with isolation and security policy" do
    response = request("/bh01/runtime-manifest.json")
    assert response.status == 200
    assert get_resp_header(response, "content-type") == ["application/json; charset=utf-8"]
    assert get_resp_header(response, "cache-control") == ["no-store"]
    assert get_resp_header(response, "cross-origin-opener-policy") == ["same-origin"]
    assert get_resp_header(response, "cross-origin-embedder-policy") == ["require-corp"]
    assert get_resp_header(response, "cross-origin-resource-policy") == ["same-origin"]

    assert get_resp_header(response, "content-security-policy") |> hd() =~
             "worker-src 'self' blob:"
  end

  test "serves immutable artifacts with ETag validation and byte ranges" do
    response = request("/bh01/artifacts/runtime.wasm")
    assert response.status == 200
    assert response.resp_body == <<0, 97, 115, 109, 1, 0, 0, 0>>
    assert get_resp_header(response, "content-type") == ["application/wasm"]
    assert get_resp_header(response, "cache-control") == ["public, max-age=31536000, immutable"]
    [etag] = get_resp_header(response, "etag")

    cached = request("/bh01/artifacts/runtime.wasm", [{"if-none-match", etag}])
    assert cached.status == 304

    range = request("/bh01/artifacts/runtime.wasm", [{"range", "bytes=0-3"}])
    assert range.status == 206
    assert range.resp_body == <<0, 97, 115, 109>>
    assert get_resp_header(range, "content-range") == ["bytes 0-3/8"]

    invalid = request("/bh01/artifacts/runtime.wasm", [{"range", "bytes=8-9"}])
    assert invalid.status == 416
  end

  test "redirects the slashless root and rejects undeclared paths" do
    assert request("/bh01").status == 308
    assert request("/bh01/not-present").status == 404
    assert request("/outside").status == 404
  end

  defp request(path, headers \\ []) do
    connection =
      Enum.reduce(headers, conn(:get, path), fn {name, value}, acc ->
        put_req_header(acc, name, value)
      end)

    @endpoint.call(connection, @endpoint.init([]))
  end
end
