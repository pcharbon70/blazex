defmodule BlazeX.ComponentContractTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.Contract

  test "role vocabulary exactly matches the behaviours" do
    for {role, behaviour} <- [
          pure: BlazeX.Component.Pure,
          stateful: BlazeX.Component.Stateful,
          root: BlazeX.Component.Root
        ] do
      %{required: required, optional: optional} = Contract.callbacks(role)

      assert Enum.sort(behaviour.behaviour_info(:callbacks)) ==
               Enum.sort(Enum.map(required ++ optional, &{&1, 1}))

      assert Enum.sort(behaviour.behaviour_info(:optional_callbacks)) ==
               Enum.sort(Enum.map(optional, &{&1, 1}))
    end
  end

  test "only roots have acknowledgement and retry callbacks" do
    for role <- [:pure, :stateful] do
      refute Contract.callback?(role, :commit_ack)
      refute Contract.callback?(role, :retry)
    end

    refute Contract.callback?(:unknown, :render)
    assert Contract.result_forms(:pure, :mount) == []
    assert Contract.result_forms(:pure, :render) == [:output, :rejected]
    refute :output in Contract.result_forms(:root, :update)
  end
end
