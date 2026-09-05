defmodule BlazeX.CoreBoundaryTest do
  use ExUnit.Case, async: true

  test "the experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Core)
  end

  test "identity is structural and replacement advances only its generation" do
    assert {:ok, root} = BlazeX.Core.Identity.new({:component, "cart"})
    assert {:ok, child} = BlazeX.Core.Identity.child(root, {:item, 7})
    assert child.path == [{:item, 7}]
    assert child.generation == 1

    assert {:ok, replacement} = BlazeX.Core.Identity.replace(child)
    assert replacement.root == child.root
    assert replacement.path == child.path
    assert replacement.generation == 2
  end

  test "identity accepts only bounded portable keys" do
    assert BlazeX.Core.Identity.portable_key?(:root)
    assert BlazeX.Core.Identity.portable_key?({:item, [1, "two"]})

    refute BlazeX.Core.Identity.portable_key?(nil)
    refute BlazeX.Core.Identity.portable_key?(self())
    refute BlazeX.Core.Identity.portable_key?(make_ref())
    refute BlazeX.Core.Identity.portable_key?(fn -> :opaque end)
    refute BlazeX.Core.Identity.portable_key?(%{opaque: true})
    refute BlazeX.Core.Identity.portable_key?(1.5)
    refute BlazeX.Core.Identity.portable_key?([:valid | :improper])
  end

  test "identity rejects malformed roots and generations" do
    assert {:error, :invalid_root} = BlazeX.Core.Identity.new(%{})
    assert {:error, :invalid_generation} = BlazeX.Core.Identity.new(:root, 0)
    assert {:error, :invalid_key} = BlazeX.Core.Identity.child(valid_root(), self())
  end

  defp valid_root do
    {:ok, identity} = BlazeX.Core.Identity.new(:test)
    identity
  end
end
