defmodule BlazeX.UITree.FormStateTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{FormState, FormOutput, Node, Document, IntentSet}

  test "closed state, explicit option membership and bounded edit acknowledgements" do
    {:ok, owner} = Identity.new(:form)
    {:ok, option} = Identity.child(owner, :option)
    choices = [%{value: "alpha", owner: option}]
    assert {:ok, _} = FormState.new(owner, :text, "hello")
    assert {:ok, _} = FormState.new(owner, :check, false, indeterminate: true)
    assert {:ok, _} = FormState.new(owner, :multiple, ["alpha"], choices: choices)

    for value <- [["missing"], ["alpha", "alpha"]] do
      assert {:error, _} = FormState.new(owner, :multiple, value, choices: choices)
    end

    assert {:error, _} = FormState.new(owner, :text, String.duplicate("x", 2049))
    assert {:error, _} = FormState.new(owner, :text, "x", edit_sequence: -1)
    assert {:error, _} = FormState.new(owner, :text, "x", path: "forbidden")
    assert {:error, _} = FormState.new(owner, :file, "forbidden")
  end

  test "output validates owners, choices and cannot be consumed as a legacy intent set" do
    {:ok, owner} = Identity.new(:form)
    {:ok, child} = Identity.child(owner, :field)
    {:ok, field} = Node.new(:field, child, key: :field)
    {:ok, root} = Node.container(:group, owner, [field])
    {:ok, document} = Document.new(root, [])
    {:ok, intent} = IntentSet.new(document)
    {:ok, form} = FormState.new(child, :text, "initial")
    assert {:ok, output} = FormOutput.new(intent, [form])
    assert {:error, _} = IntentSet.validate(output)
    assert {:error, _} = FormOutput.new(intent, [form, form])
    assert {:error, _} = FormOutput.new(intent, [%{form | owner: owner}])
    assert {:error, _} = FormOutput.validate(%{output | version: 2})
  end
end
