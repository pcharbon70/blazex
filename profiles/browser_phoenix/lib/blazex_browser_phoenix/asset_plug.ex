defmodule BlazeXBrowserPhoenix.AssetPlug do
  @moduledoc false
  import Plug.Conn

  @content_types %{
    ".html" => "text/html; charset=utf-8",
    ".js" => "text/javascript; charset=utf-8",
    ".mjs" => "text/javascript; charset=utf-8",
    ".json" => "application/json; charset=utf-8",
    ".wasm" => "application/wasm",
    ".avm" => "application/vnd.atomvm.avm"
  }

  def init(options), do: options

  def call(%Plug.Conn{method: method, request_path: "/bh01"} = conn, _options)
      when method in ["GET", "HEAD"] do
    conn
    |> put_resp_header("location", "/bh01/")
    |> put_resp_header("cache-control", "no-store")
    |> send_resp(308, "")
    |> halt()
  end

  def call(%Plug.Conn{method: method, path_info: ["bh01" | segments]} = conn, _options)
      when method in ["GET", "HEAD"] do
    relative = if segments == [], do: "index.html", else: Enum.join(segments, "/")

    with true <- safe_relative?(relative),
         root <- static_root(),
         path <- Path.expand(relative, root),
         true <- inside?(path, root),
         {:ok, stat} <- File.stat(path),
         true <- stat.type == :regular do
      serve(conn, path, relative, stat.size)
    else
      _ -> conn
    end
  end

  def call(conn, _options), do: conn

  defp serve(conn, path, relative, size) do
    digest = :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
    etag = ~s("#{digest}")

    conn =
      conn
      |> put_resp_header("content-type", content_type(relative))
      |> put_resp_header("accept-ranges", "bytes")
      |> put_resp_header("etag", etag)
      |> put_resp_header("cache-control", cache_control(relative))

    cond do
      etag in get_req_header(conn, "if-none-match") ->
        conn |> send_resp(304, "") |> halt()

      conn.method == "HEAD" ->
        conn
        |> put_resp_header("content-length", Integer.to_string(size))
        |> send_resp(200, "")
        |> halt()

      true ->
        send_range_or_file(conn, path, size)
    end
  end

  defp send_range_or_file(conn, path, size) do
    case get_req_header(conn, "range") do
      [] -> conn |> send_file(200, path) |> halt()
      [range] -> serve_range(conn, path, size, range)
      _ -> range_not_satisfiable(conn, size)
    end
  end

  defp serve_range(conn, path, size, "bytes=" <> specification) do
    case String.split(specification, ",") do
      [single] ->
        case parse_range(single, size) do
          {:ok, first, last} ->
            conn
            |> put_resp_header("content-range", "bytes #{first}-#{last}/#{size}")
            |> send_file(206, path, first, last - first + 1)
            |> halt()

          :error ->
            range_not_satisfiable(conn, size)
        end

      _ ->
        range_not_satisfiable(conn, size)
    end
  end

  defp serve_range(conn, _path, size, _range), do: range_not_satisfiable(conn, size)

  defp parse_range(specification, size) do
    case String.split(specification, "-", parts: 2) do
      [first, last] when first != "" ->
        with {start, ""} <- Integer.parse(first),
             {finish, ""} <- parse_last(last, size - 1),
             true <- start >= 0 and start <= finish and finish < size do
          {:ok, start, finish}
        else
          _ -> :error
        end

      ["", suffix] ->
        with {length, ""} <- Integer.parse(suffix),
             true <- length > 0 do
          {:ok, max(0, size - length), size - 1}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp parse_last("", fallback), do: {fallback, ""}
  defp parse_last(value, _fallback), do: Integer.parse(value)

  defp range_not_satisfiable(conn, size) do
    conn
    |> put_resp_header("content-range", "bytes */#{size}")
    |> send_resp(416, "")
    |> halt()
  end

  defp safe_relative?(relative) do
    relative != "" and
      not String.starts_with?(relative, "/") and
      Enum.all?(Path.split(relative), &(&1 not in [".", "..", ""]))
  end

  defp inside?(path, root), do: path == root or String.starts_with?(path, root <> "/")

  defp static_root do
    Application.get_env(
      :blazex_browser_phoenix,
      :static_root,
      Application.app_dir(:blazex_browser_phoenix, "priv/static/bh01")
    )
    |> Path.expand()
  end

  defp content_type(relative),
    do: Map.get(@content_types, Path.extname(relative), "application/octet-stream")

  defp cache_control(relative) when relative in ["index.html", "runtime-manifest.json"],
    do: "no-store"

  defp cache_control(_relative), do: "public, max-age=31536000, immutable"
end
