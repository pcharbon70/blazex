defmodule BlazeX.BH01.BrowserHost do
  @moduledoc false
  @compile {:no_warn_undefined, Popcorn.Wasm}

  @generation 1
  @scenario :browser_host_boot

  def start do
    trace(1, :entry, :starting, :pending)
    :ok = Popcorn.Wasm.ready(:main)
    trace(2, :host_boundary, :application_ready, :pending)

    receive do
      :phase4_no_message -> trace(999, :host_boundary, :unexpected_message, :incomplete)
    after
      100 -> trace(3, :entry, :shutdown, :complete)
    end

    :ok
  end

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
