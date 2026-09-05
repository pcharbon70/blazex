defmodule BlazeX.SemanticKernelIntegrationTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.UITree.Node

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
end
