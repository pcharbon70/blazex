defmodule BlazeX.Renderer.DOM.ContinuitySessionTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Node, Document, Binding, IntentSet, FormState, FormOutput}
  alias BlazeX.Renderer.DOM.{ContinuitySession, Portable}

  defmodule Field do
    @behaviour BlazeX.Core.Component
    def mode, do: :stateful
    def init(_, _), do: {:ok, %{value: "initial", sequence: 0}}
    def update(_, state, _), do: {:ok, state}

    def handle_event(event, _, _, _),
      do: {:ok, %{value: event.payload["value"], sequence: event.sequence}, []}

    def render(_, state, context) do
      {:ok, id} = Identity.child(context.identity, :field)
      {:ok, node} = Node.new(:field, id, key: :field)
      {:ok, root} = Node.container(:group, context.identity, [node])
      {:ok, binding} = Binding.new(:change, context.identity, id)
      {:ok, document} = Document.new(root, [binding])
      {:ok, intent} = IntentSet.new(document)
      {:ok, form} = FormState.new(id, :text, state.value, edit_sequence: state.sequence)
      FormOutput.new(intent, [form])
    end
  end

  def ack(envelope) do
    tx = envelope["transaction"]

    inner =
      tx
      |> Map.take(
        ~w(protocol schema owner generation root base_revision target_revision transaction_id digest)
      )
      |> Map.merge(%{"record" => "ack", "state" => "committed", "diagnostic" => nil})

    %{"state" => "committed", "ack" => inner, "continuity_digest" => envelope["digest"]}
  end

  test "manifest and transaction are jointly acknowledged, with old consumers kept separate" do
    {:ok, owner} = Identity.new(:form)
    {:ok, state, envelope} = ContinuitySession.mount("form", 2, Field, owner, %{})
    assert envelope["controls"] |> hd() |> Map.fetch!("value") == "initial"

    assert {:error, _} =
             ContinuitySession.acknowledge(state, 0, %{
               ack(envelope)
               | "continuity_digest" => String.duplicate("0", 64)
             })

    assert {:ok, state} = ContinuitySession.acknowledge(state, 0, ack(envelope))
    {:ok, source} = Identity.child(owner, :field)
    source = Portable.id(source)

    record =
      Map.merge(state.context, %{
        "protocol" => "blazex.interaction/1",
        "provenance" => "local-event",
        "source" => source,
        "listener_id" => "li-" <> source <> "-change",
        "semantic" => "change",
        "sequence" => 1,
        "timestamp" => 1,
        "payload" => %{"value" => "edited", "checked" => false}
      })

    assert {:ok, candidate, response} = ContinuitySession.deliver(state, record)
    assert candidate.evaluation.state.value == "initial"

    assert {:ok, accepted} =
             ContinuitySession.acknowledge(candidate, 1, ack(response["transaction"]))

    assert accepted.evaluation.state.value == "edited"
    assert {:error, _} = ContinuitySession.deliver(accepted, record)
  end
end
