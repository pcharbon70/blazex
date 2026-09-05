defmodule BlazeX.RendererBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.{Artifact, Capabilities, Diagnostic, Negotiation, Requirements, Session}

  alias BlazeX.UITree.{
    Accessibility,
    Binding,
    Document,
    Focus,
    IntentSet,
    Layout,
    Node,
    Selection
  }

  defmodule CompleteBackend do
    @behaviour BlazeX.Renderer.Backend

    alias BlazeX.Renderer.{Artifact, Capabilities}

    @impl true
    def capabilities, do: Capabilities.full()

    @impl true
    def mount(_output, context), do: result([], context)

    @impl true
    def update(state, _output, context), do: result(state, context)

    @impl true
    def replace(state, _output, context), do: result(state, context)

    @impl true
    def dispose(state, context), do: result(state, context)

    defp result(state, context) do
      {:ok, artifact} =
        Artifact.new(:test, {context.transition, context.generation, context.revision})

      {:ok, state ++ [context.transition], artifact}
    end
  end

  defmodule LimitedBackend do
    @behaviour BlazeX.Renderer.Backend

    alias BlazeX.Renderer.{Artifact, Capabilities}

    @impl true
    def capabilities do
      {:ok, capabilities} =
        Capabilities.new(
          tree_versions: [1],
          node_kinds: [:group, :action, :selection],
          layout_modes: [],
          accessibility_roles: [],
          features: [:event_bindings]
        )

      capabilities
    end

    @impl true
    def mount(_output, _context), do: artifact()

    @impl true
    def update(_state, _output, _context), do: artifact()

    @impl true
    def replace(_state, _output, _context), do: artifact()

    @impl true
    def dispose(_state, _context), do: artifact()

    defp artifact do
      {:ok, artifact} = Artifact.new(:limited, nil)
      {:ok, nil, artifact}
    end
  end

  defmodule RejectingBackend do
    @behaviour BlazeX.Renderer.Backend

    alias BlazeX.Renderer.{Artifact, Capabilities}

    @impl true
    def capabilities, do: Capabilities.full()
    @impl true
    def mount(_output, _context), do: {:error, %{secret: self()}}
    @impl true
    def update(_state, _output, _context), do: invalid_artifact()
    @impl true
    def replace(_state, _output, _context), do: raise("private renderer failure")
    @impl true
    def dispose(_state, _context), do: {:ok, nil, %{not: :an_artifact}}

    defp invalid_artifact do
      {:ok, artifact} = Artifact.new(:invalid, nil)
      {:ok, nil, %{artifact | version: 2}}
    end
  end

  test "the contract boundary sees only approved host-neutral packages" do
    assert Code.ensure_loaded?(BlazeX.Core)
    assert Code.ensure_loaded?(BlazeX.Effects)
    assert Code.ensure_loaded?(BlazeX.UITree)
    assert Code.ensure_loaded?(BlazeX.Renderer)
  end

  test "renderer capability vocabulary and full declaration are exact" do
    capabilities = Capabilities.full()
    assert Capabilities.tree_versions() == [1]

    assert Capabilities.features() == [
             :event_bindings,
             :logical_layout,
             :accessibility,
             :focus,
             :selection
           ]

    assert capabilities.node_kinds == Node.kinds()
    assert capabilities.layout_modes == Layout.modes()
    assert capabilities.accessibility_roles == Accessibility.roles()
    assert Capabilities.valid?(capabilities)

    assert {:error, :invalid_renderer_features} =
             Capabilities.new(
               tree_versions: [1],
               node_kinds: [],
               layout_modes: [],
               accessibility_roles: [],
               features: [:pixels]
             )
  end

  test "requirements derive all used semantic features in canonical order" do
    output = intent_set!(identity!(:renderer))
    assert {:ok, requirements} = Requirements.derive(output)
    assert requirements.tree_version == 1
    assert requirements.node_kinds == [:group, :action, :selection]
    assert requirements.layout_modes == [:stack]
    assert requirements.accessibility_roles == [:group, :button, :list_item]

    assert requirements.features == [
             :event_bindings,
             :logical_layout,
             :accessibility,
             :focus,
             :selection
           ]

    assert {:ok, %Negotiation{}} = Negotiation.negotiate(Capabilities.full(), requirements)
  end

  test "negotiation denies missing renderer features before mount" do
    output = intent_set!(identity!(:limited))

    assert {:error,
            %Diagnostic{
              code: :missing_renderer_capability,
              stage: :negotiate,
              detail: %{layout_modes: [:stack]}
            }} = Session.mount(LimitedBackend, output)
  end

  test "session enforces ordered mount update replacement and idempotent disposal" do
    owner = identity!(:lifecycle)
    output = intent_set!(owner)
    assert {:ok, mounted} = Session.mount(CompleteBackend, output)
    assert mounted.status == :mounted
    assert mounted.revision == 0
    assert mounted.backend_state == [:mount]
    assert mounted.artifact.value == {:mount, 1, 0}

    assert {:ok, updated} = Session.update(mounted, output)
    assert updated.revision == 1
    assert updated.backend_state == [:mount, :update]
    assert {:ok, replacement_owner} = Identity.replace(owner)
    replacement = intent_set!(replacement_owner)
    assert {:ok, replaced} = Session.replace(updated, replacement)
    assert replaced.generation == 2
    assert replaced.revision == 0
    assert replaced.backend_state == [:mount, :update, :replace]

    assert {:ok, disposed} = Session.dispose(replaced)
    assert disposed.status == :disposed
    assert disposed.backend_state == [:mount, :update, :replace, :dispose]
    assert {:ok, same} = Session.dispose(disposed)
    assert same == disposed
    assert {:error, %Diagnostic{code: :session_disposed}} = Session.update(disposed, replacement)
  end

  test "session rejects wrong owners and nonconsecutive replacement generations" do
    owner = identity!(:owned)
    assert {:ok, mounted} = Session.mount(CompleteBackend, intent_set!(owner))
    other = identity!(:other)

    assert {:error, %Diagnostic{code: :renderer_owner_mismatch}} =
             Session.update(mounted, intent_set!(other))

    assert {:ok, generation_2} = Identity.replace(owner)
    assert {:ok, generation_3} = Identity.replace(generation_2)

    assert {:error, %Diagnostic{code: :invalid_renderer_replacement}} =
             Session.replace(mounted, intent_set!(generation_3))

    assert mounted.revision == 0
    assert mounted.backend_state == [:mount]
  end

  test "backend failures and malformed artifacts become stable diagnostics" do
    output = intent_set!(identity!(:failures))
    assert {:error, rejected} = Session.mount(RejectingBackend, output)
    assert rejected.code == :backend_rejected
    assert rejected.detail == :mount
    refute inspect(rejected) =~ "secret"

    assert {:ok, mounted} = Session.mount(CompleteBackend, output)
    rejecting = %{mounted | backend: RejectingBackend}

    assert {:error, %Diagnostic{code: :invalid_artifact, stage: :update}} =
             Session.update(rejecting, output)

    assert {:error, %Diagnostic{code: :backend_failed, stage: :replace}} =
             Session.replace(rejecting, intent_set!(identity!(:failures, 2)))

    assert {:error, %Diagnostic{code: :invalid_backend_result, stage: :dispose}} =
             Session.dispose(rejecting)
  end

  test "invalid semantic output fails before lifecycle state changes" do
    owner = identity!(:invalid_output)
    assert {:ok, mounted} = Session.mount(CompleteBackend, intent_set!(owner))

    assert {:error, %Diagnostic{code: :invalid_semantic_output}} =
             Session.update(mounted, %{raw: true})

    assert mounted.revision == 0
    assert mounted.backend_state == [:mount]
  end

  defp intent_set!(owner) do
    {:ok, action_id} = Identity.child(owner, :action)
    {:ok, selection_id} = Identity.child(owner, :selection)
    {:ok, action} = Node.container(:action, action_id, [], key: :action)
    {:ok, selection_node} = Node.container(:selection, selection_id, [], key: :selection)
    {:ok, root} = Node.container(:group, owner, [action, selection_node])
    {:ok, binding} = Binding.new(:activate, owner, action_id)
    {:ok, document} = Document.new(root, [binding])
    {:ok, layout} = Layout.new(owner, :stack)
    {:ok, root_accessibility} = Accessibility.new(owner, :group)
    {:ok, action_accessibility} = Accessibility.new(action_id, :button, name: "Run")
    {:ok, selection_accessibility} = Accessibility.new(selection_id, :list_item, name: "One")
    {:ok, focus} = Focus.new(action_id, :target, order: 0)
    {:ok, selection} = Selection.new(selection_id, :single, :one)

    {:ok, intent_set} =
      IntentSet.new(document,
        layouts: [layout],
        accessibility: [root_accessibility, action_accessibility, selection_accessibility],
        focus: [focus],
        selections: [selection]
      )

    intent_set
  end

  defp identity!(root, generation \\ 1) do
    {:ok, identity} = Identity.new(root, generation)
    identity
  end
end
