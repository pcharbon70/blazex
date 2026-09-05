defmodule BlazeX.TestBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.{Artifact, Capabilities}
  alias BlazeX.Test.RenderScript
  alias BlazeX.UITree.Node

  defmodule RecordingBackend do
    @behaviour BlazeX.Renderer.Backend

    def capabilities, do: Capabilities.full()
    def mount(output, context), do: artifact([], output, context)
    def update(state, output, context), do: artifact(state, output, context)
    def replace(state, output, context), do: artifact(state, output, context)
    def dispose(state, context), do: artifact(state, nil, context)

    defp artifact(state, output, context) do
      entry = {context.transition, context.generation, context.revision, output}
      next = state ++ [entry]
      {:ok, next, %Artifact{version: 1, format: :recording, value: next}}
    end
  end

  test "runs a backend-neutral lifecycle script" do
    first = node!(:script, 1)
    replacement = node!(:script, 2)

    assert {:ok, session} =
             RenderScript.run(RecordingBackend, [
               {:mount, first},
               {:update, first},
               {:replace, replacement},
               :dispose,
               :dispose
             ])

    assert session.status == :disposed
    assert Enum.map(session.backend_state, &elem(&1, 0)) == [:mount, :update, :replace, :dispose]
  end

  test "rejects malformed scripts and propagates renderer diagnostics" do
    assert {:error, :invalid_renderer_script} = RenderScript.run(RecordingBackend, [])
    assert {:error, :invalid_renderer_script} = RenderScript.run(RecordingBackend, [:dispose])

    assert {:error, %BlazeX.Renderer.Diagnostic{code: :session_disposed}} =
             RenderScript.run(RecordingBackend, [
               {:mount, node!(:closed, 1)},
               :dispose,
               {:update, node!(:closed, 1)}
             ])
  end

  test "asserts exact artifact equality" do
    node = node!(:equality, 1)
    {:ok, left} = RenderScript.run(RecordingBackend, [{:mount, node}])
    {:ok, right} = RenderScript.run(RecordingBackend, [{:mount, node}])
    assert :ok = RenderScript.assert_artifact_equal!(left, right)

    {:ok, changed} = RenderScript.run(RecordingBackend, [{:mount, node}, {:update, node}])

    assert_raise ArgumentError, "renderer artifacts differ", fn ->
      RenderScript.assert_artifact_equal!(left, changed)
    end
  end

  defp node!(root, generation) do
    {:ok, identity} = Identity.new(root, generation)
    {:ok, node} = Node.new(:group, identity)
    node
  end
end
