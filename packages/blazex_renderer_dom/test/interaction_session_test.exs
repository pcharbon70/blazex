defmodule BlazeX.Renderer.DOM.InteractionSessionTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.Renderer.DOM.{InteractionSession, Portable, ReconciledSession}
  alias BlazeX.UITree.{Binding, Document, Node}

  defmodule Counter do
    @behaviour BlazeX.Core.Component
    def mode, do: :stateful
    def init(_, _), do: {:ok, 0}
    def update(_, state, _), do: {:ok, state}
    def handle_event(_, _, state, _), do: {:ok, state + 1, []}

    def render(_, state, context) do
      {:ok, label_id} = Identity.child(context.identity, :label)
      {:ok, label} = Node.text(label_id, "Events: #{state}", key: :label)

      children =
        Enum.map(Event.names(), fn event ->
          {:ok, id} = Identity.child(context.identity, event)

          {:ok, node} =
            Node.new(if(event in [:change, :select], do: :field, else: :action), id, key: event)

          node
        end)

      {:ok, root} = Node.container(:group, context.identity, [label | children])

      bindings =
        Enum.map(Event.names(), fn event ->
          {:ok, id} = Identity.child(context.identity, event)
          {:ok, binding} = Binding.new(event, context.identity, id)
          binding
        end)

      Document.new(root, bindings)
    end
  end

  def ack(tx),
    do:
      tx
      |> Map.take(
        ~w(protocol schema owner generation root base_revision target_revision transaction_id digest)
      )
      |> Map.merge(%{"record" => "ack", "state" => "committed", "diagnostic" => nil})

  def mounted(root \\ "one") do
    {:ok, owner} = Identity.new(root)
    {:ok, state, tx} = InteractionSession.mount(root, 2, Counter, owner, %{})
    {:ok, state} = InteractionSession.acknowledge(state, 0, ack(tx))
    {state, owner}
  end

  def record(state, owner, event, sequence \\ 1) do
    {:ok, id} = Identity.child(owner, event)
    source = Portable.id(id)

    payload =
      case event do
        e when e in [:change, :select] -> %{"value" => "hello", "checked" => false}
        :move -> %{"x" => 1.25, "y" => -2, "dx" => 0.5, "dy" => -0.25, "buttons" => 1}
        :reorder -> %{"source" => source}
        _ -> %{}
      end

    Map.merge(state.context, %{
      "protocol" => "blazex.interaction/1",
      "provenance" => "local-event",
      "source" => source,
      "listener_id" => "li-" <> source <> "-" <> Atom.to_string(event),
      "semantic" => Atom.to_string(event),
      "payload" => payload,
      "sequence" => sequence,
      "timestamp" => 1
    })
  end

  test "all semantic mappings dispatch through existing callbacks and await actual renderer acknowledgement" do
    for event <- Event.names() do
      {state, owner} = mounted()
      {:ok, pending, result} = InteractionSession.deliver(state, record(state, owner, event))
      assert state.evaluation.state == 0 and pending.evaluation.state == 0
      assert pending.candidate.state == 1
      assert result["transaction"] == ReconciledSession.transaction(pending.renderer)
      assert {:error, _} = InteractionSession.deliver(pending, record(state, owner, event, 2))
      {:ok, accepted} = InteractionSession.acknowledge(pending, 1, ack(result["transaction"]))
      assert accepted.evaluation.state == 1 and accepted.context["revision"] == 2
      assert {:error, _} = InteractionSession.deliver(accepted, record(state, owner, event))
    end
  end

  test "wrong root, revision, listener, replay, unbound and oversized inputs never dispatch" do
    {state, owner} = mounted()
    valid = record(state, owner, :activate)

    for bad <- [
          Map.put(valid, "root_id", "other"),
          Map.put(valid, "revision", 0),
          Map.put(valid, "generation", 2),
          Map.put(valid, "listener_id", "unknown"),
          Map.put(valid, "payload", %{"password" => "private"}),
          Map.put(valid, "extra", true),
          Map.put(valid, "provenance", "server-command"),
          Map.put(valid, "sequence", 0),
          Map.put(record(state, owner, :change), "payload", %{
            "value" => String.duplicate("x", 2049),
            "checked" => false
          })
        ] do
      assert {:error, _} = InteractionSession.deliver(state, bad)
      assert state.evaluation.state == 0
    end

    assert {:error, _} = InteractionSession.deliver(InteractionSession.stop(state), valid)
  end

  test "bridge protocol and request identity are distinct from legacy fixture handling" do
    {state, owner} = mounted()

    request = %{
      "protocol" => "blazex.host-bridge/2",
      "operation" => "root.interaction",
      "root_id" => "one",
      "request_id" => "test",
      "payload" => record(state, owner, :activate)
    }

    assert {:ok, _, %{"request_id" => "test", "protocol" => "blazex.host-bridge/2"}} =
             InteractionSession.handle(state, request)

    for bad <- [
          Map.put(request, "protocol", "blazex.host-bridge/1"),
          Map.put(request, "operation", "fixture.event"),
          Map.put(request, "root_id", "other")
        ] do
      assert {:error, _} = InteractionSession.handle(state, bad)
    end
  end

  test "independent sessions cannot advance each other's owner" do
    {a, owner} = mounted("one")
    {b, _} = mounted("two")
    assert {:error, _} = InteractionSession.deliver(b, record(a, owner, :activate))
    assert {:ok, _, _} = InteractionSession.deliver(a, record(a, owner, :activate))
    assert b.evaluation.state == 0
  end
end
