defmodule BlazeX.UITreeBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.UITree.{Binding, Document, Node}

  defmodule PureLabel do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure

    @impl true
    def render(props, context), do: Node.text(context.identity, props.label)
  end

  defmodule StatefulList do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(props, _context), do: {:ok, props.items}

    @impl true
    def update(props, _state, _context), do: {:ok, props.items}

    @impl true
    def render(_props, items, context) do
      children =
        Enum.map(items, fn item ->
          {:ok, item_identity} = Identity.child(context.identity, {:item, item})
          {:ok, node} = Node.container(:action, item_identity, [], key: {:item, item})
          node
        end)

      Node.container(:collection, context.identity, children)
    end
  end

  defmodule InvalidTree do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure

    @impl true
    def render(_props, _context), do: {:ok, %{kind: :raw}}
  end

  defmodule WrongRoot do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure

    @impl true
    def render(_props, _context) do
      {:ok, wrong_identity} = Identity.new(:wrong)
      Node.container(:group, wrong_identity, [])
    end
  end

  defmodule InvalidUpdateTree do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(_props, _context), do: {:ok, :valid}

    @impl true
    def update(_props, _state, _context), do: {:ok, :invalid}

    @impl true
    def render(_props, :valid, context), do: Node.container(:group, context.identity, [])
    def render(_props, :invalid, _context), do: {:ok, %{kind: :raw}}
  end

  defmodule InteractiveCounter do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(props, _context), do: {:ok, %{count: props.initial}}

    @impl true
    def update(_props, state, _context), do: {:ok, state}

    @impl true
    def handle_event(%Event{name: :increment, payload: payload}, _props, state, _context) do
      {:ok, %{state | count: state.count + payload.amount}, [{:schedule, payload.amount}]}
    end

    @impl true
    def render(_props, _state, context) do
      key = {:action, :increment}
      {:ok, source} = Identity.child(context.identity, key)
      {:ok, action} = Node.container(:action, source, [], key: key)
      {:ok, root} = Node.container(:group, context.identity, [action])
      {:ok, binding} = Binding.new(:increment, context.identity, source)
      Document.new(root, [binding])
    end
  end

  defmodule InvalidEventRender do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(_props, _context), do: {:ok, :valid}

    @impl true
    def update(_props, state, _context), do: {:ok, state}

    @impl true
    def handle_event(_event, _props, _state, _context), do: {:ok, :invalid, []}

    @impl true
    def render(_props, :valid, context) do
      {:ok, root} = Node.container(:action, context.identity, [])
      {:ok, binding} = Binding.new(:activate, context.identity, context.identity)
      Document.new(root, [binding])
    end

    def render(_props, :invalid, _context), do: {:ok, %{raw: true}}
  end

  test "the boundary depends inward only on core" do
    assert Code.ensure_loaded?(BlazeX.Core)
    assert Code.ensure_loaded?(BlazeX.UITree)
  end

  test "version 1 tree validates and traverses in deterministic preorder" do
    {:ok, root_id} = Identity.new({:component, "toolbar"})
    {:ok, text_id} = Identity.child(root_id, {:position, 0})
    {:ok, save_id} = Identity.child(root_id, {:action, :save})
    {:ok, text} = Node.text(text_id, "Actions")
    {:ok, save} = Node.container(:action, save_id, [], key: {:action, :save})
    {:ok, root} = Node.container(:group, root_id, [text, save])

    assert :ok = BlazeX.UITree.validate(root)
    assert {:ok, [^root, ^text, ^save]} = BlazeX.UITree.preorder(root)
  end

  test "keyed reorder preserves semantic identity" do
    {:ok, root_id} = Identity.new(:list)
    {:ok, first_id} = Identity.child(root_id, {:item, 1})
    {:ok, second_id} = Identity.child(root_id, {:item, 2})
    {:ok, first} = Node.container(:action, first_id, [], key: {:item, 1})
    {:ok, second} = Node.container(:action, second_id, [], key: {:item, 2})

    assert {:ok, before} = Node.container(:collection, root_id, [first, second])
    assert {:ok, after_reorder} = Node.container(:collection, root_id, [second, first])
    assert Enum.map(before.children, & &1.identity) == [first_id, second_id]
    assert Enum.map(after_reorder.children, & &1.identity) == [second_id, first_id]
  end

  test "tree rejects duplicate sibling identities and keys" do
    {:ok, root_id} = Identity.new(:duplicates)
    {:ok, child_id} = Identity.child(root_id, :same)
    {:ok, child} = Node.container(:action, child_id, [], key: :same)

    assert {:error, %{code: :duplicate_sibling_identity, path: []}} =
             Node.container(:collection, root_id, [child, child])

    {:ok, alternate_id} = Identity.child(root_id, {:alternate, :same})
    alternate = %{child | identity: alternate_id}

    assert {:error, %{code: :duplicate_sibling_key, path: []}} =
             Node.container(:collection, root_id, [child, alternate])
  end

  test "tree rejects malformed ancestry and content" do
    {:ok, root_id} = Identity.new(:root)
    {:ok, foreign_root} = Identity.new(:foreign)
    {:ok, foreign_child_id} = Identity.child(foreign_root, :child)
    {:ok, foreign_child} = Node.container(:group, foreign_child_id, [])

    assert {:error, %{code: :invalid_child_identity, path: [0]}} =
             Node.container(:group, root_id, [foreign_child])

    assert {:error, %{code: :invalid_content}} = Node.text(root_id, "")
    assert {:error, %{code: :invalid_content}} = Node.new(:group, root_id, content: "raw")
  end

  test "tree rejects unknown versions, kinds, and key mismatches" do
    {:ok, root_id} = Identity.new(:root)
    {:ok, child_id} = Identity.child(root_id, :expected)

    assert {:error, %{code: :unknown_kind}} = Node.new(:unknown, root_id)

    assert {:error, %{code: :key_identity_mismatch}} =
             Node.new(:action, child_id, key: :different)

    invalid_version = %Node{
      version: 2,
      kind: :group,
      identity: root_id,
      key: nil,
      content: nil,
      children: []
    }

    assert {:error, %{code: :unsupported_version}} = BlazeX.UITree.validate(invalid_version)
  end

  test "pure component output is accepted only with its component identity" do
    {:ok, identity} = Identity.new(:label)
    assert {:ok, mounted} = BlazeX.UITree.mount_component(PureLabel, identity, %{label: "One"})
    assert mounted.output.content == "One"
    assert mounted.output.identity == identity

    assert {:ok, updated} = BlazeX.UITree.update_component(mounted, %{label: "Two"})
    assert updated.output.content == "Two"
    assert updated.identity == identity
    assert updated.revision == 1
  end

  test "stateful keyed reorder retains child identity" do
    {:ok, identity} = Identity.new(:items)

    assert {:ok, mounted} =
             BlazeX.UITree.mount_component(StatefulList, identity, %{items: [1, 2]})

    before = Map.new(mounted.output.children, &{&1.key, &1.identity})
    assert {:ok, updated} = BlazeX.UITree.update_component(mounted, %{items: [2, 1]})
    after_reorder = Map.new(updated.output.children, &{&1.key, &1.identity})
    assert before == after_reorder
    assert Enum.map(updated.output.children, & &1.key) == [{:item, 2}, {:item, 1}]
  end

  test "replacement remounts semantic output under a new generation" do
    {:ok, identity} = Identity.new(:items)

    assert {:ok, mounted} =
             BlazeX.UITree.mount_component(StatefulList, identity, %{items: [1]})

    assert {:ok, replaced} = BlazeX.UITree.replace_component(mounted, %{items: [1]})
    assert replaced.identity.generation == 2
    assert replaced.output.identity == replaced.identity
    assert hd(replaced.output.children).identity.generation == 2
  end

  test "invalid semantic output and wrong root identity fail closed" do
    {:ok, identity} = Identity.new(:invalid)

    assert {:error, %{code: :invalid_semantic_output, detail: :malformed_node}} =
             BlazeX.UITree.mount_component(InvalidTree, identity, %{})

    assert {:error, %{code: :root_identity_mismatch}} =
             BlazeX.UITree.mount_component(WrongRoot, identity, %{})
  end

  test "failed update leaves the previously accepted evaluation unchanged" do
    {:ok, identity} = Identity.new(:atomic)
    assert {:ok, mounted} = BlazeX.UITree.mount_component(InvalidUpdateTree, identity, %{})

    assert {:error, %{code: :invalid_semantic_output}} =
             BlazeX.UITree.update_component(mounted, %{})

    assert mounted.revision == 0
    assert mounted.state == :valid
    assert :ok = BlazeX.UITree.validate(mounted.output)
  end

  test "semantic document validates bindings and resolves exact events" do
    {:ok, owner} = Identity.new(:document)
    {:ok, source} = Identity.child(owner, {:action, :save})
    {:ok, action} = Node.container(:action, source, [], key: {:action, :save})
    {:ok, root} = Node.container(:group, owner, [action])
    {:ok, binding} = Binding.new(:activate, owner, source)
    assert {:ok, document} = Document.new(root, [binding])
    {:ok, event} = Event.new(:activate, owner, source)
    assert {:ok, ^binding} = Document.resolve(document, event)

    assert {:error, :duplicate_binding} = Document.new(root, [binding, binding])
    {:ok, missing_source} = Identity.child(owner, {:action, :missing})
    {:ok, missing_binding} = Binding.new(:activate, owner, missing_source)
    assert {:error, :binding_source_missing} = Document.new(root, [missing_binding])
  end

  test "bound stateful dispatch validates the rerender and returns emissions" do
    {:ok, owner} = Identity.new(:counter)

    assert {:ok, mounted} =
             BlazeX.UITree.mount_component(InteractiveCounter, owner, %{initial: 2})

    [binding] = mounted.output.bindings
    {:ok, event} = Event.new(:increment, owner, binding.source, %{amount: 3}, 1)

    assert {:ok, dispatched, [{:schedule, 3}]} =
             BlazeX.UITree.dispatch_component(mounted, event)

    assert dispatched.state == %{count: 5}
    assert dispatched.revision == 1
    assert Document.validate(dispatched.output) == :ok
  end

  test "unbound and invalid event rerenders leave prior evaluation usable" do
    {:ok, owner} = Identity.new(:event_failure)
    assert {:ok, mounted} = BlazeX.UITree.mount_component(InvalidEventRender, owner, %{})

    {:ok, unbound} = Event.new(:dismiss, owner, owner, %{}, 1)

    assert {:error, %{code: :unbound_event}} =
             BlazeX.UITree.dispatch_component(mounted, unbound)

    {:ok, bound} = Event.new(:activate, owner, owner, %{}, 1)

    assert {:error, %{code: :invalid_semantic_output}} =
             BlazeX.UITree.dispatch_component(mounted, bound)

    assert mounted.state == :valid
    assert mounted.revision == 0
    assert Document.validate(mounted.output) == :ok
  end
end
