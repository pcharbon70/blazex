defmodule BlazeX.Renderer.DOM.EffectSessionTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.Identity
  alias BlazeX.Effects.Effect
  alias BlazeX.UITree.{Node, Document, Binding, IntentSet, FormOutput}
  alias BlazeX.Renderer.DOM.{ContinuitySession, Portable}

  defmodule Component do
    def mode, do: :stateful
    def init(_, _), do: {:ok, 0}
    def update(_, state, _), do: {:ok, state}

    def handle_event(event, _, state, _) do
      {:ok, effect} =
        Effect.new("tick-#{event.sequence}", event.owner, :time, :schedule, %{"delay_ms" => 1},
          timeout_ms: 100
        )

      {:ok, state + 1, [effect]}
    end

    def render(_, state, context) do
      {:ok, id} = Identity.child(context.identity, :button)
      {:ok, button} = Node.new(:action, id, key: :button)
      {:ok, label_id} = Identity.child(context.identity, :label)
      {:ok, label} = Node.text(label_id, Integer.to_string(state), key: :label)
      {:ok, root} = Node.container(:group, context.identity, [button, label])
      {:ok, binding} = Binding.new(:activate, context.identity, id)
      {:ok, document} = Document.new(root, [binding])
      {:ok, intent} = IntentSet.new(document)
      FormOutput.new(intent, [])
    end
  end

  def ack(envelope, statuses \\ []) do
    continuity = envelope["continuity"]
    tx = continuity["transaction"]

    inner =
      tx
      |> Map.take(
        ~w(protocol schema owner generation root base_revision target_revision transaction_id digest)
      )
      |> Map.merge(%{"record" => "ack", "state" => "committed", "diagnostic" => nil})

    %{
      "state" => "committed",
      "effects_digest" => envelope["digest"],
      "results" => statuses,
      "ack" => %{
        "state" => "committed",
        "ack" => inner,
        "continuity_digest" => continuity["digest"]
      }
    }
  end

  def event(state, owner) do
    {:ok, source} = Identity.child(owner, :button)
    source = Portable.id(source)

    Map.merge(state.context, %{
      "protocol" => "blazex.interaction/1",
      "provenance" => "local-event",
      "source" => source,
      "listener_id" => "li-" <> source <> "-activate",
      "semantic" => "activate",
      "sequence" => 1,
      "timestamp" => 1,
      "payload" => %{}
    })
  end

  test "effect emissions require explicit grants and exact compound results before state promotion" do
    {:ok, owner} = Identity.new(:effects)
    {:ok, state, envelope} = ContinuitySession.mount("effects", 1, Component, owner, %{}, [:time])
    assert {:ok, state} = ContinuitySession.acknowledge(state, 0, ack(envelope))
    assert {:ok, pending, response} = ContinuitySession.deliver(state, event(state, owner))
    assert pending.evaluation.state == 0
    emitted = response["transaction"]

    assert [%{"capability" => "time", "id" => "tick-1"}] =
             Enum.map(emitted["effects"], &Map.take(&1, ~w(capability id)))

    for rows <- [
          [],
          [%{"id" => "foreign", "status" => "ok"}],
          [%{"id" => "tick-1", "status" => "timeout"}]
        ] do
      assert {:error, _} = ContinuitySession.acknowledge(pending, 1, ack(emitted, rows))
    end

    assert {:ok, accepted} =
             ContinuitySession.acknowledge(
               pending,
               1,
               ack(emitted, [%{"id" => "tick-1", "status" => "ok"}])
             )

    assert accepted.evaluation.state == 1
    assert [%BlazeX.Effects.Result{status: :ok, effect_id: "tick-1"}] = accepted.effect_results
    assert {:error, _} = ContinuitySession.deliver(accepted, event(state, owner))
    assert ContinuitySession.stop(accepted).effect_results == []
    assert {:error, _} = ContinuitySession.deliver(%{state | grants: []}, event(state, owner))
    assert {:error, _} = ContinuitySession.deliver(%{state | grants: nil}, event(state, owner))
  end
end
