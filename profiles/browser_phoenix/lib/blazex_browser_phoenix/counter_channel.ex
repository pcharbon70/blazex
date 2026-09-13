defmodule BlazeXBrowserPhoenix.CounterChannel do
  @moduledoc false
  use Phoenix.Channel

  alias BlazeX.Phoenix.CommandExecution

  @topic "bh07:counter"
  @join_protocol "blazex.bh07.push-join/1"
  @max_safe_integer 9_007_199_254_740_991

  @impl true
  def join(@topic, payload, socket) do
    with ["after_sequence", "protocol"] <- Enum.sort(Map.keys(payload)),
         @join_protocol <- payload["protocol"],
         cursor when is_integer(cursor) and cursor in 0..@max_safe_integer <-
           payload["after_sequence"],
         {:ok, sync} <-
           CommandExecution.subscribe(
             socket.assigns.bh07_session_id,
             socket.assigns.bh07_csrf_token,
             cursor
           ) do
      {:ok, sync, socket}
    else
      {:error, code} -> {:error, error(code)}
      _ -> {:error, error("push-join-invalid")}
    end
  end

  def join(_topic, _payload, _socket), do: {:error, error("push-topic-invalid")}

  @impl true
  def handle_in(_event, _payload, socket),
    do: {:reply, {:error, error("push-client-event-denied")}, socket}

  @impl true
  def handle_info({:blazex_counter_update, event}, socket) do
    push(socket, "counter", event)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, _socket) do
    CommandExecution.unsubscribe()
    :ok
  end

  defp error(code) do
    %{
      "protocol" => "blazex.bh07.push-error/1",
      "error" => %{"code" => code}
    }
  end
end
