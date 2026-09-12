defmodule BlazeX.BH06.VerticalSlice.Counter do
  @moduledoc "Public Elixir component used by the BH-06 browser-Wasm gate."

  use BlazeX.Component,
    role: :root,
    schema: [props: [{"label", [type: :string, required: true]}], slots: []]

  def mount(_input), do: {:state, 0}
  def update(_input), do: :no_change
  def handle_event(%{state: {:present, count}}), do: {:state, count + 1}
  def handle_info(_input), do: :no_change

  def render(%{props: %{"label" => label}, state: {:present, count}}) do
    {:output,
     {:semantic, 1,
      %{
        kind: :button,
        text: label <> ": " <> Integer.to_string(count),
        binding: :activate,
        accessibility: %{role: :button, name: label}
      }}}
  end

  def terminate(_input), do: :ok
end
