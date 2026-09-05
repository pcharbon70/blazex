defmodule BlazeX.Test.RenderScript do
  @moduledoc """
  Executes an explicit renderer lifecycle script against any backend.
  """

  alias BlazeX.Renderer.Session

  @type step :: {:mount, term()} | {:update, term()} | {:replace, term()} | :dispose

  @spec run(module(), [step()]) :: {:ok, Session.t()} | {:error, term()}
  def run(backend, [{:mount, output} | steps]) when is_list(steps) do
    with {:ok, session} <- Session.mount(backend, output) do
      Enum.reduce_while(steps, {:ok, session}, &execute/2)
    end
  end

  def run(_backend, _script), do: {:error, :invalid_renderer_script}

  @spec assert_artifact_equal!(Session.t(), Session.t()) :: :ok
  def assert_artifact_equal!(%Session{} = left, %Session{} = right) do
    if left.artifact == right.artifact do
      :ok
    else
      raise ArgumentError, "renderer artifacts differ"
    end
  end

  def assert_artifact_equal!(_left, _right),
    do: raise(ArgumentError, "renderer sessions required")

  defp execute({:update, output}, {:ok, session}), do: continue(Session.update(session, output))
  defp execute({:replace, output}, {:ok, session}), do: continue(Session.replace(session, output))
  defp execute(:dispose, {:ok, session}), do: continue(Session.dispose(session))
  defp execute(_step, {:ok, _session}), do: {:halt, {:error, :invalid_renderer_script}}

  defp continue({:ok, session}), do: {:cont, {:ok, session}}
  defp continue({:error, error}), do: {:halt, {:error, error}}
end
