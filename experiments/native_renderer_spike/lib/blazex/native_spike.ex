defmodule BlazeX.NativeSpike do
  @moduledoc """
  Disposable BH-02 backend that projects portable semantics to native-control
  intent without exposing a platform object to the renderer contract.
  """

  @behaviour BlazeX.Renderer.Backend

  alias BlazeX.NativeSpike.{Batch, State}
  alias BlazeX.Renderer.{Artifact, Capabilities, Context}

  @impl true
  def capabilities do
    {:ok, capabilities} =
      Capabilities.new(
        tree_versions: [1],
        node_kinds: [:text, :group, :action, :field, :selection, :collection, :surface],
        layout_modes: [:none, :stack],
        accessibility_roles: [
          :generic,
          :text,
          :group,
          :button,
          :text_field,
          :checkbox,
          :list,
          :list_item,
          :dialog,
          :status
        ],
        features: [:event_bindings, :logical_layout, :accessibility, :focus, :selection]
      )

    capabilities
  end

  @impl true
  def mount(output, %Context{} = context), do: project(output, context)

  @impl true
  def update(%State{}, output, %Context{} = context), do: project(output, context)

  @impl true
  def replace(%State{}, output, %Context{} = context), do: project(output, context)

  @impl true
  def dispose(%State{}, %Context{} = context) do
    batch = Batch.dispose(context)
    {:ok, %State{batch: batch}, artifact(batch)}
  end

  defp project(output, context) do
    with {:ok, batch} <- Batch.project(output, context) do
      {:ok, %State{batch: batch}, artifact(batch)}
    end
  end

  defp artifact(batch), do: %Artifact{version: 1, format: :native_control_batch, value: batch}
end
