defmodule BlazeX.SemanticKernelIntegrationTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.Effects.{Effect, Result, Tracker}
  alias BlazeX.UITree.{Binding, Document, Node}

  defmodule StatefulActions do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(props, _context), do: {:ok, props.actions}

    @impl true
    def update(props, _state, _context), do: {:ok, props.actions}

    @impl true
    def render(_props, actions, context) do
      children =
        Enum.map(actions, fn action ->
          key = {:action, action}
          {:ok, identity} = Identity.child(context.identity, key)
          {:ok, node} = Node.container(:action, identity, [], key: key)
          node
        end)

      Node.container(:collection, context.identity, children)
    end
  end

  defmodule EffectfulClipboard do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(_props, _context), do: {:ok, %{requests: 0}}

    @impl true
    def update(_props, state, _context), do: {:ok, state}

    @impl true
    def handle_event(%Event{name: :activate}, _props, state, context) do
      {:ok, effect} =
        Effect.new(
          {:clipboard, state.requests + 1},
          context.identity,
          :"ui.clipboard",
          :read,
          %{},
          timeout_ms: 1_000,
          fallback: :component
        )

      {:ok, %{requests: state.requests + 1}, [effect]}
    end

    @impl true
    def render(_props, _state, context) do
      key = {:action, :read_clipboard}
      {:ok, source} = Identity.child(context.identity, key)
      {:ok, action} = Node.container(:action, source, [], key: key)
      {:ok, root} = Node.container(:group, context.identity, [action])
      {:ok, binding} = Binding.new(:activate, context.identity, source)
      Document.new(root, [binding])
    end
  end

  test "composed profile preserves keyed identity through update and replacement" do
    {:ok, identity} = Identity.new({:component, :actions})

    assert {:ok, mounted} =
             BlazeX.UITree.mount_component(StatefulActions, identity, %{actions: [:save, :close]})

    mounted_identities = Map.new(mounted.output.children, &{&1.key, &1.identity})

    assert {:ok, updated} =
             BlazeX.UITree.update_component(mounted, %{actions: [:close, :save, :share]})

    assert Enum.map(updated.output.children, & &1.key) == [
             {:action, :close},
             {:action, :save},
             {:action, :share}
           ]

    assert updated.output.children
           |> Enum.take(2)
           |> Enum.all?(fn node -> mounted_identities[node.key] == node.identity end)

    assert {:ok, replaced} =
             BlazeX.UITree.replace_component(updated, %{actions: [:close, :save]})

    assert replaced.identity.generation == 2
    assert Enum.all?(replaced.output.children, &(&1.identity.generation == 2))
    assert :ok = BlazeX.UITree.validate(replaced.output)
  end

  test "semantic intent emits a typed effect and owner cleanup closes its lifecycle" do
    {:ok, owner} = Identity.new({:component, :clipboard})
    assert {:ok, mounted} = BlazeX.UITree.mount_component(EffectfulClipboard, owner, %{})
    [binding] = mounted.output.bindings
    {:ok, event} = Event.new(:activate, owner, binding.source, %{}, 1)

    assert {:ok, dispatched, [effect]} = BlazeX.UITree.dispatch_component(mounted, event)
    assert %Effect{owner: ^owner, capability: :"ui.clipboard", operation: :read} = effect
    assert dispatched.state == %{requests: 1}

    assert {:ok, tracker} = Tracker.new([:"ui.clipboard"])
    assert {:ok, pending, :pending} = Tracker.submit(tracker, effect)

    assert {:ok, cleaned, [%Result{effect_id: {:clipboard, 1}, status: :cancelled}]} =
             Tracker.dispose_owner(pending, owner)

    assert cleaned.pending == %{}

    assert {:error, %{code: :effect_not_pending}} =
             Tracker.complete(cleaned, effect.id, %{text: "late"})
  end
end
