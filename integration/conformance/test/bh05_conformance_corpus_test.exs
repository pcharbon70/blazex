Code.require_file("../../bh-05/conformance-components.exs", __DIR__)

defmodule BlazeX.BH05ConformanceCorpusTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.Conformance.{Fault, Item, Root}
  alias BlazeX.Component.Input

  test "public corpus declarations and callback results remain portable" do
    assert Root.__blazex_component__().role == :root
    assert Item.__blazex_component__().role == :stateful
    assert Fault.__blazex_component__().role == :root
    assert {:state, 0} = Root.mount(%{})
    assert {:state, 1} = Root.handle_event(%{state: {:present, 0}})
    assert {:output, output} = Root.render(%{state: {:present, 1}})
    assert Input.portable?(output)
    assert {:error, :injected} = Fault.render(%{})
    assert :ok = Root.terminate(%{})
  end
end
