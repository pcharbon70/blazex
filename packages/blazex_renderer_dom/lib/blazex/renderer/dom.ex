defmodule BlazeX.Renderer.DOM do
  @moduledoc """
  Experimental server-independent DOM projection backend.

  It lowers complete semantic output into a deterministic, versioned wire
  projection. Browser mutation is owned by the companion JavaScript driver.
  """

  @behaviour BlazeX.Renderer.Backend

  alias BlazeX.Renderer.{Artifact, Capabilities, Context}
  alias BlazeX.Renderer.DOM.{Batch, State}

  @impl true
  def capabilities, do: Capabilities.full()

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

  defp artifact(batch), do: %Artifact{version: 1, format: :dom_batch, value: batch}
end
