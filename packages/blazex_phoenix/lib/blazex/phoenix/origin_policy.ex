defmodule BlazeX.Phoenix.OriginPolicy do
  @moduledoc "Canonical same-origin validation independent of a web adapter."

  @schemes ["http", "https"]

  def authorize(origin_headers, expected_scheme, expected_host, expected_port) do
    with [origin] <- origin_headers,
         {:ok, actual} <- canonical(origin),
         {:ok, expected} <- expected(expected_scheme, expected_host, expected_port),
         true <- actual == expected do
      :ok
    else
      _ -> {:error, "origin-invalid"}
    end
  end

  def canonical(value) when is_binary(value) do
    with {:ok, uri} <- URI.new(value),
         true <- uri.scheme in @schemes,
         true <- is_binary(uri.host) and uri.host != "",
         true <- is_nil(uri.userinfo),
         true <- uri.path in [nil, ""],
         true <- is_nil(uri.query),
         true <- is_nil(uri.fragment),
         port when is_integer(port) <- uri.port do
      {:ok, {uri.scheme, String.downcase(uri.host), port}}
    else
      _ -> {:error, "origin-invalid"}
    end
  end

  def canonical(_value), do: {:error, "origin-invalid"}

  defp expected(scheme, host, port) when is_atom(scheme),
    do: expected(Atom.to_string(scheme), host, port)

  defp expected(scheme, host, port)
       when scheme in @schemes and is_binary(host) and host != "" and is_integer(port) and
              port in 1..65_535,
       do: {:ok, {scheme, String.downcase(host), port}}

  defp expected(_scheme, _host, _port), do: {:error, "origin-invalid"}
end
