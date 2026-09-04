defmodule BlazeX.BH01.BrowserHost do
  @moduledoc false
  @compile {:no_warn_undefined, Popcorn.Wasm}

  @generation 1
  @scenario :browser_host_boot
  alias BlazeX.BH01.LocalBehavior
  alias BlazeX.BH01.BrowserHost.Protocol

  def start do
    trace(1, :entry, :starting, :pending)
    LocalBehavior.initialize(@generation)
    :ok = Popcorn.Wasm.ready(:main)
    trace(2, :host_boundary, :application_ready, :pending)

    loop(3)
  end

  defp loop(sequence) do
    receive do
      {:bh01_fixture_timer, _generation, _token} = message ->
        publish_async(message)
        loop(sequence + 1)

      {:bh01_fixture_message, _generation, _message_id, _value} = message ->
        publish_async(message)
        loop(sequence + 1)

      message ->
        case Popcorn.Wasm.handle_message!(message, &handle_message/1) do
          :shutdown -> trace(sequence, :host_boundary, :shutdown, :complete)
          _ -> loop(sequence + 1)
        end
    after
      30_000 -> trace(sequence, :entry, :idle_timeout, :complete)
    end

    :ok
  end

  defp publish_async(message) do
    case LocalBehavior.async(message) do
      {:ok, effect, _result} -> Popcorn.Wasm.send_event("bh01_fixture_effect", effect)
      {:error, error} -> Popcorn.Wasm.send_event("bh01_fixture_async_error", error)
    end
  end

  defp handle_message({:wasm_call, request}) do
    case Protocol.handle(request) do
      {:ok, response, "runtime.shutdown"} -> {:resolve, response, :shutdown}
      {:ok, response, _operation} -> {:resolve, response, :continue}
      {:error, response} -> {:resolve, response, :continue}
    end
  end

  defp handle_message({:wasm_cast, %{"type" => "cancel"}}), do: :cancel_acknowledged
  defp handle_message(_), do: :ignored

  defp trace(sequence, process, result, cleanup) do
    :erlang.display(
      {:bxtrace,
       [
         generation: @generation,
         scenario: @scenario,
         process: process,
         sequence: sequence,
         result: result,
         error: :none,
         cleanup: cleanup
       ]}
    )
  end
end
