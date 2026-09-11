defmodule BlazeX.BH06.VerticalSlice.Browser do
  @moduledoc false
  @compile {:no_warn_undefined, Popcorn.Wasm}

  alias BlazeX.BH06.VerticalSlice.Counter

  def start do
    :ok = Popcorn.Wasm.ready(:main)
    loop(:unmounted, [])
  end

  defp loop(state, trace) do
    receive do
      message ->
        next = self()

        outcome =
          Popcorn.Wasm.handle_message!(message, fn request ->
            {reply, new_state, new_trace, action} = handle(request, state, trace)
            send(next, {:bh06_next, new_state, new_trace, action})
            {:resolve, reply, :continue}
          end)

        receive do
          {:bh06_next, new_state, new_trace, :continue} -> loop(new_state, new_trace)
          {:bh06_next, _, _, :shutdown} -> :ok
        after
          1_000 -> :erlang.error({:missing_transition, outcome})
        end
    after
      30_000 -> :ok
    end
  end

  defp handle({:wasm_call, %{"operation" => "mount"}}, :unmounted, trace) do
    input = %{props: %{"label" => "Wasm counter"}, slots: %{}, state: :none}
    {:state, count} = Counter.mount(input)
    projection = render(count)
    step = %{"step" => "mount", "state" => count, "semantic" => 1}
    {response("mounted", count, projection, trace ++ [step]), count, trace ++ [step], :continue}
  end

  defp handle({:wasm_call, %{"operation" => "event", "name" => "activate"}}, count, trace)
       when is_integer(count) do
    {:state, next} = Counter.handle_event(%{state: {:present, count}})
    projection = render(next)
    step = %{"step" => "event", "name" => "activate", "state" => next}
    {response("updated", next, projection, trace ++ [step]), next, trace ++ [step], :continue}
  end

  defp handle({:wasm_call, %{"operation" => "dispose"}}, count, trace)
       when is_integer(count) do
    :ok = Counter.terminate(%{state: {:present, count}})
    final = trace ++ [%{"step" => "dispose", "state" => count, "resources" => 0}]
    {%{"result" => "disposed", "state" => count, "trace" => final}, :disposed, final, :shutdown}
  end

  defp handle(_, state, trace),
    do: {%{"result" => "rejected", "state" => encode_state(state)}, state, trace, :continue}

  defp render(count) do
    {:output, {:semantic, 1, node}} =
      Counter.render(%{
        props: %{"label" => "Wasm counter"},
        slots: %{},
        state: {:present, count}
      })

    %{
      "version" => 1,
      "kind" => Atom.to_string(node.kind),
      "text" => node.text,
      "binding" => Atom.to_string(node.binding),
      "role" => Atom.to_string(node.accessibility.role),
      "name" => node.accessibility.name
    }
  end

  defp response(result, state, projection, trace),
    do: %{"result" => result, "state" => state, "projection" => projection, "trace" => trace}

  defp encode_state(state) when is_atom(state), do: Atom.to_string(state)
  defp encode_state(state), do: state
end
