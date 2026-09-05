defmodule BlazeX.Renderer.HeadlessBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.{Context, Diagnostic, Session}
  alias BlazeX.Renderer.Headless
  alias BlazeX.Renderer.Headless.{Snapshot, Trace}
  alias BlazeX.UITree.{Accessibility, Binding, Document, Node}

  test "declares the complete frozen capability set" do
    assert Headless.capabilities() == BlazeX.Renderer.Capabilities.full()
  end

  test "repeated snapshots have byte-stable SHA-256 digests" do
    output = document!(:repeatability, [:first, :second])
    {:ok, context} = Context.new(output.root.identity, 0, :mount)

    assert {:ok, first} = Snapshot.build(output, context)
    assert {:ok, second} = Snapshot.build(output, context)
    assert first == second
    assert byte_size(first.digest) == 64
    assert first.digest =~ ~r/^[0-9a-f]{64}$/
  end

  test "unordered declarations and maps normalize independently of insertion order" do
    first = document!(:normalization, [:first, :second])
    second = %{first | bindings: Enum.reverse(first.bindings)}
    root = first.root.identity
    target = hd(first.root.children).identity

    {:ok, first_accessibility} =
      Accessibility.new(root, :group,
        states: Map.new([{:busy, false}, {:disabled, true}]),
        relationships: Map.new([{:controls, [target]}, {:labelled_by, [target]}])
      )

    {:ok, second_accessibility} =
      Accessibility.new(root, :group,
        states: Map.new([{:disabled, true}, {:busy, false}]),
        relationships: Map.new([{:labelled_by, [target]}, {:controls, [target]}])
      )

    first_intent = intent_with_accessibility!(first, first_accessibility)
    second_intent = intent_with_accessibility!(second, second_accessibility)
    {:ok, context} = Context.new(root, 0, :mount)

    assert {:ok, left} = Snapshot.build(first_intent, context)
    assert {:ok, right} = Snapshot.build(second_intent, context)
    assert left == right
  end

  test "meaningful child order changes the digest" do
    first = document!(:child_order, [:first, :second])
    second = %{first | root: %{first.root | children: Enum.reverse(first.root.children)}}
    {:ok, context} = Context.new(first.root.identity, 0, :mount)

    assert {:ok, left} = Snapshot.build(first, context)
    assert {:ok, right} = Snapshot.build(second, context)
    refute left.digest == right.digest
  end

  test "records exact lifecycle order, revisions, replacement, and disposal" do
    first = document!(:lifecycle, [:first])
    {:ok, mounted} = Session.mount(Headless, first)
    {:ok, updated} = Session.update(mounted, first)

    replacement = replace_document!(first)
    {:ok, replaced} = Session.replace(updated, replacement)
    {:ok, disposed} = Session.dispose(replaced)
    {:ok, disposed_again} = Session.dispose(disposed)

    assert disposed == disposed_again
    assert disposed.status == :disposed
    assert disposed.artifact.format == :headless_trace
    assert %Trace{entries: entries} = disposed.backend_state.trace
    assert Enum.map(entries, & &1.sequence) == [1, 2, 3, 4]
    assert Enum.map(entries, & &1.transition) == [:mount, :update, :replace, :dispose]
    assert Enum.map(entries, & &1.revision) == [0, 1, 0, 0]
    assert Enum.map(entries, & &1.generation) == [1, 1, 2, 2]
    assert List.last(entries).digest == replaced.backend_state.snapshot.digest
  end

  test "unsupported semantic output fails before the headless callback" do
    valid = document!(:unsupported, [:first])
    invalid = %{valid | root: %{valid.root | kind: :image}}

    assert {:error,
            %Diagnostic{
              code: :invalid_semantic_output,
              stage: :mount,
              backend: Headless
            }} = Session.mount(Headless, invalid)
  end

  defp document!(root_key, child_keys) do
    {:ok, root_identity} = Identity.new(root_key)

    children =
      Enum.map(child_keys, fn key ->
        {:ok, identity} = Identity.child(root_identity, key)
        {:ok, node} = Node.new(:action, identity, key: key)
        node
      end)

    {:ok, root} = Node.container(:group, root_identity, children)

    bindings =
      Enum.map(children, fn child ->
        {:ok, binding} = Binding.new(:activate, root_identity, child.identity)
        binding
      end)

    {:ok, document} = Document.new(root, bindings)
    document
  end

  defp intent_with_accessibility!(document, accessibility) do
    {:ok, intent_set} = BlazeX.UITree.IntentSet.new(document, accessibility: [accessibility])
    intent_set
  end

  defp replace_document!(document) do
    {:ok, identity} = Identity.replace(document.root.identity)

    children =
      Enum.map(document.root.children, fn child ->
        key = child.key
        {:ok, child_identity} = Identity.child(identity, key)
        {:ok, next} = Node.new(child.kind, child_identity, key: key)
        next
      end)

    {:ok, root} = Node.container(:group, identity, children)

    bindings =
      Enum.map(children, fn child ->
        {:ok, binding} = Binding.new(:activate, identity, child.identity)
        binding
      end)

    {:ok, replacement} = Document.new(root, bindings)
    replacement
  end
end
