defmodule BlazeX.UITreeBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.UITree.Node

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
end
