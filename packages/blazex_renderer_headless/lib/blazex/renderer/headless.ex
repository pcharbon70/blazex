defmodule BlazeX.Renderer.Headless do
  @moduledoc """
  Deterministic, nonvisual renderer oracle.

  The backend records canonical semantic snapshots and ordered lifecycle
  traces. It performs no measurement, geometry, host access, or drawing.
  """

  @behaviour BlazeX.Renderer.Backend

  alias BlazeX.Renderer.{Artifact, Capabilities, Context}
  alias BlazeX.Renderer.Headless.{Snapshot, State, Trace}

  @impl true
  def capabilities, do: Capabilities.full()

  @impl true
  def mount(output, %Context{} = context), do: transition(nil, output, context)

  @impl true
  def update(%State{} = state, output, %Context{} = context),
    do: transition(state, output, context)

  @impl true
  def replace(%State{} = state, output, %Context{} = context),
    do: transition(state, output, context)

  @impl true
  def dispose(%State{} = state, %Context{transition: :dispose} = context) do
    trace = Trace.append(state.trace, context, state.snapshot.digest)
    next = %{state | trace: trace}
    {:ok, next, %Artifact{version: 1, format: :headless_trace, value: trace}}
  end

  defp transition(state, output, context) do
    with {:ok, snapshot} <- Snapshot.build(output, context) do
      trace = Trace.append((state && state.trace) || Trace.new(), context, snapshot.digest)
      next = %State{snapshot: snapshot, trace: trace}
      {:ok, next, %Artifact{version: 1, format: :headless_snapshot, value: snapshot}}
    end
  end
end
