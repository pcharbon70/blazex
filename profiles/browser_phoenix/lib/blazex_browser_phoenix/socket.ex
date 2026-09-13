defmodule BlazeXBrowserPhoenix.Socket do
  @moduledoc false
  use Phoenix.Socket

  alias BlazeX.Phoenix.SessionRegistry

  channel("bh07:counter", BlazeXBrowserPhoenix.CounterChannel)

  @protocol "blazex.bh07.push-connect/1"

  @impl true
  def connect(params, socket, connect_info) do
    application_params = Map.drop(params, ["vsn"])

    with ["csrf_token", "protocol"] <- Enum.sort(Map.keys(application_params)),
         @protocol <- application_params["protocol"],
         csrf when is_binary(csrf) <- application_params["csrf_token"],
         true <- valid_transport_version?(params),
         session when is_map(session) <- connect_info[:session],
         session_id when is_binary(session_id) <- session_value(session, :bh07_session_id),
         {:ok, context} <- SessionRegistry.authority_context(session_id, csrf) do
      {:ok,
       socket
       |> assign(:bh07_session_id, session_id)
       |> assign(:bh07_csrf_token, csrf)
       |> assign(:bh07_expires_at_ms, context.expires_at_ms)}
    else
      _ -> :error
    end
  end

  @impl true
  def id(_socket), do: nil

  defp session_value(session, key),
    do: Map.get(session, key) || Map.get(session, Atom.to_string(key))

  defp valid_transport_version?(%{"vsn" => value}),
    do: is_binary(value) and byte_size(value) in 1..16

  defp valid_transport_version?(_params), do: true
end
