# Test-only stdio carrier. Component dispatch and reconciliation are real Elixir;
# no Phoenix/Plug/network server and no claim of fresh browser-Wasm packaging.
jason = Path.expand("../../fixtures/browser_host/deps/jason/lib/**/*.ex", __DIR__)
{:ok, _, _} = Kernel.ParallelCompiler.compile(Path.wildcard(jason))
Code.require_file("effect_component.exs", __DIR__)

defmodule BlazeX.BH04.EffectRuntime do
  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.Renderer.DOM.ContinuitySession

  def run(states \\ %{}) do
    case IO.read(:stdio, :line) do
      :eof ->
        :ok

      {:error, _} ->
        :ok

      line ->
        {next, output, id} =
          try do
            true = byte_size(line) <= 16384
            %{"id" => id, "request" => request} = Jason.decode!(line)
            {next, output} = execute(states, request)
            {next, output, id}
          rescue
            error ->
              IO.puts(:stderr, Exception.format(:error, error, __STACKTRACE__))
              {states, %{"error" => "fixture-invalid"}, nil}
          end

        IO.puts("BH07:" <> Jason.encode!(%{"id" => id, "result" => output}))
        run(next)
    end
  end

  defp execute(states, %{
         "control" => "init",
         "root_id" => root,
         "lifecycle_generation" => generation
       }) do
    true = map_size(states) < 64 or Map.has_key?(states, root)
    true = not Map.has_key?(states, root) or states[root].disposed
    {:ok, owner} = Identity.new(root)

    {:ok, state, tx} =
      ContinuitySession.mount(root, generation, BlazeX.BH04.EffectComponent, owner, %{}, [:time])

    {Map.put(states, root, state),
     %{"transaction" => tx, "events" => Enum.map(Event.names(), &Atom.to_string/1)}}
  end

  defp execute(states, %{"control" => "initial_ack", "root_id" => root, "ack" => ack}) do
    {:ok, state} = ContinuitySession.acknowledge(Map.fetch!(states, root), 0, ack)
    {Map.put(states, root, state), %{"outcome" => "committed"}}
  end

  defp execute(states, %{"control" => "update", "root_id" => root, "props" => props}) do
    case ContinuitySession.update(Map.fetch!(states, root), props) do
      {:ok, state, envelope} -> {Map.put(states, root, state), %{"transaction" => envelope}}
      _ -> {states, %{"error" => "fixture-update"}}
    end
  end

  defp execute(states, %{"control" => "update_ack", "root_id" => root, "ack" => ack}) do
    state = Map.fetch!(states, root)
    {:ok, state} = ContinuitySession.acknowledge(state, state.pending_sequence, ack)
    {Map.put(states, root, state), %{"outcome" => "committed"}}
  end

  defp execute(states, %{"control" => "stop", "root_id" => root}) do
    state = ContinuitySession.stop(Map.fetch!(states, root))
    {Map.put(states, root, state), %{"outcome" => "disposed"}}
  end

  defp execute(states, %{"control" => "snapshot", "root_id" => root}) do
    state = Map.fetch!(states, root)

    {states,
     %{
       "count" => if(state.evaluation, do: state.evaluation.state, else: nil),
       "sequence" => state.last_sequence,
       "revision" => if(state.context, do: state.context["revision"], else: nil),
       "disposed" => state.disposed,
       "pending" => state.pending_sequence,
       "effects" =>
         Enum.map(
           state.effect_results,
           &%{"id" => &1.effect_id, "status" => Atom.to_string(&1.status)}
         )
     }}
  end

  defp execute(states, %{"protocol" => "blazex.host-bridge/4", "root_id" => root} = request) do
    case ContinuitySession.handle(Map.fetch!(states, root), request) do
      {:ok, state, response} -> {Map.put(states, root, state), response}
      {:error, code} -> {states, %{"error" => code}}
    end
  end

  defp execute(states, _), do: {states, %{"error" => "fixture-incompatible"}}
end

IO.puts("BH07:ready")
BlazeX.BH04.EffectRuntime.run()
