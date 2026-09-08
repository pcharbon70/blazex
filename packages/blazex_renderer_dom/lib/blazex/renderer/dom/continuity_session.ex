defmodule BlazeX.Renderer.DOM.ContinuitySession do
  @moduledoc "Experimental root-local semantic dispatch with acknowledged render state. Explicit opt-in effects; no concrete transport or atoms from wire."
  alias BlazeX.Core.Event
  alias BlazeX.UITree.{FormEvaluator, FormOutput, Document, IntentSet}
  alias BlazeX.Renderer.DOM.{Portable, ContinuityRenderer, EffectBatch}
  @header ~w(root_id lifecycle_generation owner generation revision transaction_id digest)
  @keys ~w(protocol provenance root_id lifecycle_generation owner source listener_id generation revision transaction_id digest sequence timestamp semantic payload)
  @names Enum.map(Event.names(), &Atom.to_string/1)
  @maximum 9_007_199_254_740_991
  defstruct [
    :root_id,
    :lifecycle_generation,
    :evaluation,
    :renderer,
    :candidate,
    :context,
    :pending_sequence,
    grants: nil,
    effect_envelope: nil,
    pending_effects: [],
    effect_results: [],
    seen_effect_ids: [],
    last_sequence: 0,
    disposed: false
  ]

  def mount(root_id, lifecycle_generation, component, identity, props, grants \\ nil) do
    with true <- EffectBatch.grants?(grants),
         true <- is_binary(root_id) and Regex.match?(~r/\A[a-z][a-z0-9-]{0,63}\z/, root_id),
         true <- integer?(lifecycle_generation, 1),
         {:ok, evaluation} <- FormEvaluator.mount(component, identity, props),
         {:ok, renderer} <- ContinuityRenderer.mount(evaluation.output) do
      state = %__MODULE__{
        root_id: root_id,
        lifecycle_generation: lifecycle_generation,
        renderer: renderer,
        candidate: evaluation,
        pending_sequence: 0,
        grants: grants
      }

      propose(state, [])
    else
      _ -> {:error, "mount"}
    end
  end

  def acknowledge(
        %__MODULE__{disposed: false, pending_sequence: sequence, candidate: candidate} = state,
        sequence,
        ack
      )
      when candidate != nil do
    tx = ContinuityRenderer.header(state.renderer)

    with {:ok, ack, results} <- effect_ack(state, ack),
         {:ok, renderer} <- ContinuityRenderer.acknowledge(state.renderer, ack),
         true <- ack["state"] == "committed" and renderer.pending == nil do
      context = %{
        "root_id" => state.root_id,
        "lifecycle_generation" => state.lifecycle_generation,
        "owner" => tx["owner"],
        "generation" => tx["generation"],
        "revision" => tx["target_revision"],
        "transaction_id" => tx["transaction_id"],
        "digest" => tx["digest"]
      }

      {:ok,
       %{
         state
         | renderer: renderer,
           evaluation: candidate,
           candidate: nil,
           pending_sequence: nil,
           context: context,
           last_sequence: sequence,
           effect_envelope: nil,
           pending_effects: [],
           effect_results: results,
           seen_effect_ids: state.seen_effect_ids ++ Enum.map(state.pending_effects, & &1.id)
       }}
    else
      _ -> {:error, "render"}
    end
  end

  def acknowledge(_, _, _), do: {:error, "stale"}

  def update(%__MODULE__{disposed: false, pending_sequence: nil} = state, props) do
    with {:ok, candidate} <- FormEvaluator.update(state.evaluation, props),
         {:ok, renderer} <- ContinuityRenderer.update(state.renderer, candidate.output) do
      propose(
        %{
          state
          | renderer: renderer,
            candidate: candidate,
            pending_sequence: state.last_sequence
        },
        []
      )
    end
  end

  def update(_, _), do: {:error, "stale"}

  def deliver(%__MODULE__{} = state, record) do
    with :ok <- validate(record),
         true <- not state.disposed and state.context != nil and state.pending_sequence == nil,
         true <- Enum.all?(@header, &(record[&1] == state.context[&1])),
         true <- record["sequence"] > state.last_sequence,
         binding when binding != nil <- resolve(state.evaluation.output, record),
         {:ok, event} <-
           Event.new(
             binding.event,
             binding.owner,
             binding.source,
             record["payload"],
             record["sequence"]
           ),
         {:ok, candidate, effects} <-
           FormEvaluator.dispatch(
             state.evaluation,
             event,
             &(EffectBatch.valid?(&1, state.evaluation.identity, state.grants) and
                 length(state.seen_effect_ids) + length(&1) <= 256 and
                 Enum.all?(&1, fn effect -> effect.id not in state.seen_effect_ids end))
           ) do
      if candidate.output == state.evaluation.output and effects == [] do
        {:ok, %{state | evaluation: candidate, last_sequence: record["sequence"]},
         %{"ack" => ack(record, "accepted", nil), "transaction" => nil}}
      else
        case ContinuityRenderer.update(state.renderer, candidate.output) do
          {:ok, renderer} ->
            {:ok, proposed, envelope} =
              propose(
                %{
                  state
                  | renderer: renderer,
                    candidate: candidate,
                    pending_sequence: record["sequence"]
                },
                effects
              )

            {:ok, proposed, %{"ack" => ack(record, "accepted", nil), "transaction" => envelope}}

          _ ->
            {:error, "render"}
        end
      end
    else
      {:error, code} when is_binary(code) -> {:error, code}
      _ -> {:error, "stale-or-unbound"}
    end
  end

  def handle(%__MODULE__{} = state, request) do
    with true <- exact?(request, ~w(protocol root_id request_id operation payload)),
         true <-
           request["protocol"] ==
             if(state.grants == nil, do: "blazex.host-bridge/3", else: "blazex.host-bridge/4") and
             request["root_id"] == state.root_id,
         true <- is_binary(request["request_id"]) and byte_size(request["request_id"]) in 1..96,
         true <- bounded?(request, 0) and json_size(request) <= 8192 do
      result =
        case request["operation"] do
          "root.interaction" ->
            deliver(state, request["payload"])

          "root.render_ack" ->
            payload = request["payload"]

            if exact?(payload, ~w(sequence ack)) do
              case acknowledge(state, payload["sequence"], payload["ack"]) do
                {:ok, next} ->
                  {:ok, next, %{"outcome" => "committed", "sequence" => payload["sequence"]}}

                error ->
                  error
              end
            else
              {:error, "malformed"}
            end

          _ ->
            {:error, "incompatible"}
        end

      case result do
        {:ok, next, value} -> {:ok, next, response(request, value)}
        {:error, code} -> {:error, code}
      end
    else
      _ -> {:error, "incompatible"}
    end
  end

  def stop(%__MODULE__{} = state),
    do: %{
      state
      | disposed: true,
        evaluation: nil,
        renderer: nil,
        candidate: nil,
        context: nil,
        pending_sequence: nil,
        pending_effects: [],
        effect_results: [],
        effect_envelope: nil,
        seen_effect_ids: []
    }

  defp propose(state, effects) do
    continuity = ContinuityRenderer.transaction(state.renderer)
    envelope = if state.grants == nil, do: continuity, else: EffectBatch.wrap(continuity, effects)

    {:ok,
     %{
       state
       | pending_effects: effects,
         effect_envelope: if(state.grants == nil, do: nil, else: envelope)
     }, envelope}
  end

  defp effect_ack(%{grants: nil}, ack), do: {:ok, ack, []}

  defp effect_ack(state, ack),
    do: EffectBatch.acknowledge(state.effect_envelope, state.pending_effects, ack)

  defp response(request, result),
    do: request |> Map.take(~w(protocol root_id request_id)) |> Map.put("result", result)

  defp ack(record, outcome, diagnostic),
    do:
      record
      |> Map.take(@header ++ ~w(sequence listener_id))
      |> Map.merge(%{"outcome" => outcome, "diagnostic" => diagnostic})

  defp resolve(%FormOutput{intent: intent}, record), do: resolve(intent, record)

  defp resolve(%IntentSet{document: document}, record), do: resolve(document, record)

  defp resolve(%Document{bindings: bindings}, record) do
    Enum.find(bindings, fn b ->
      source = Portable.id(b.source)

      Atom.to_string(b.event) == record["semantic"] and source == record["source"] and
        "li-" <> source <> "-" <> Atom.to_string(b.event) == record["listener_id"]
    end)
  end

  defp resolve(_, _), do: nil

  def validate(record) do
    if exact?(record, @keys) and bounded?(record, 0) and item_count(record) <= 64 and
         json_size(record) <= 8192 and
         record["protocol"] == "blazex.interaction/1" and record["provenance"] == "local-event" and
         match_string?(record["root_id"], ~r/\A[a-z][a-z0-9-]{0,63}\z/) and
         match_string?(record["owner"], ~r/\Aroot-[a-z0-9_-]{1,59}\z/) and
         match_string?(record["source"], ~r/\Abx-[0-9a-f]{24}\z/) and
         match_string?(record["transaction_id"], ~r/\Atx-[0-9a-f]{24}\z/) and
         match_string?(record["digest"], ~r/\A[0-9a-f]{64}\z/) and
         Enum.all?(
           ~w(lifecycle_generation generation revision sequence),
           &integer?(record[&1], 1)
         ) and integer?(record["timestamp"], 0) and
         record["semantic"] in @names and
         record["listener_id"] == "li-" <> record["source"] <> "-" <> record["semantic"] and
         payload?(record["semantic"], record["source"], record["payload"]),
       do: :ok,
       else: {:error, "malformed"}
  rescue
    _ -> {:error, "malformed"}
  end

  defp payload?(name, _, p) when name in ~w(change select),
    do:
      exact?(p, ~w(value checked)) and is_binary(p["value"]) and byte_size(p["value"]) <= 2048 and
        (is_boolean(p["checked"]) or p["checked"] == nil)

  defp payload?("move", _, p),
    do:
      exact?(p, ~w(x y dx dy buttons)) and
        Enum.all?(~w(x y dx dy), &(is_number(p[&1]) and abs(p[&1]) <= 1_000_000)) and
        is_integer(p["buttons"]) and p["buttons"] in 0..31

  defp payload?("reorder", source, p), do: exact?(p, ~w(source)) and p["source"] == source
  defp payload?(_, _, p), do: exact?(p, [])

  defp exact?(v, keys),
    do: is_map(v) and not is_struct(v) and Enum.sort(Map.keys(v)) == Enum.sort(keys)

  defp integer?(v, min), do: is_integer(v) and v >= min and v <= @maximum
  defp match_string?(value, regex), do: is_binary(value) and Regex.match?(regex, value)
  defp bounded?(_, depth) when depth > 6, do: false
  defp bounded?(v, _) when is_binary(v), do: byte_size(v) <= 2048 and String.valid?(v)
  defp bounded?(v, _) when is_number(v), do: abs(v) <= @maximum
  defp bounded?(v, _) when is_boolean(v) or is_nil(v), do: true

  defp bounded?(v, depth) when is_map(v),
    do:
      not is_struct(v) and map_size(v) <= 64 and
        Enum.all?(v, fn {k, x} ->
          is_binary(k) and bounded?(k, depth + 1) and bounded?(x, depth + 1)
        end)

  defp bounded?(v, depth) when is_list(v),
    do: length(v) <= 16 and Enum.all?(v, &bounded?(&1, depth + 1))

  defp bounded?(_, _), do: false

  defp item_count(v) when is_map(v),
    do: map_size(v) + Enum.reduce(v, 0, fn {_, x}, n -> n + item_count(x) end)

  defp item_count(_), do: 0

  defp json_size(v) when is_binary(v),
    do:
      2 +
        Enum.reduce(:binary.bin_to_list(v), 0, fn byte, n ->
          n +
            cond do
              byte in [34, 92, 8, 9, 10, 12, 13] -> 2
              byte < 32 -> 6
              true -> 1
            end
        end)

  defp json_size(v) when is_integer(v), do: byte_size(Integer.to_string(v))
  defp json_size(v) when is_float(v), do: byte_size(Float.to_string(v))
  defp json_size(nil), do: 4
  defp json_size(true), do: 4
  defp json_size(false), do: 5

  defp json_size(v) when is_list(v),
    do: 2 + max(length(v) - 1, 0) + Enum.reduce(v, 0, fn x, n -> n + json_size(x) end)

  defp json_size(v) when is_map(v),
    do:
      2 + max(map_size(v) - 1, 0) +
        Enum.reduce(v, 0, fn {k, x}, n -> n + json_size(k) + 1 + json_size(x) end)
end
