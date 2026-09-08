defmodule BlazeX.Renderer.DOM.ContinuityRenderer do
  @moduledoc "Digest-bound controlled-state companion to immutable v2 transactions."
  alias BlazeX.UITree.FormOutput
  alias BlazeX.Renderer.DOM.{Portable, ReconciledSession}
  alias BlazeX.Renderer.DOM.Protocol.Codec
  defstruct inner: nil, pending: nil, control_digest: nil

  def mount(output) do
    with :ok <- FormOutput.validate(output),
         {:ok, inner} <- ReconciledSession.mount(output.intent) do
      propose(%__MODULE__{inner: inner}, output)
    end
  end

  def update(%__MODULE__{pending: nil} = state, output) do
    with :ok <- FormOutput.validate(output),
         {:ok, inner} <- ReconciledSession.update(state.inner, output.intent) do
      propose(%{state | inner: inner}, output)
    end
  end

  def update(_, _), do: {:error, "pending-transaction"}
  def transaction(state), do: state.pending
  def header(state), do: state.pending["transaction"]

  def acknowledge(%__MODULE__{pending: pending} = state, response) when pending != nil do
    with true <-
           is_map(response) and Enum.sort(Map.keys(response)) == ~w(ack continuity_digest state),
         true <-
           response["continuity_digest"] == pending["digest"] and response["state"] == "committed",
         true <- is_map(response["ack"]) and response["ack"]["state"] == "committed",
         {:ok, inner} <- ReconciledSession.acknowledge(state.inner, response["ack"]),
         true <- inner.pending == nil do
      {:ok, %{state | inner: inner, pending: nil, control_digest: pending["control_digest"]}}
    else
      _ -> {:error, "render"}
    end
  end

  def acknowledge(_, _), do: {:error, "stale"}

  defp propose(state, output) do
    controls =
      Enum.map(output.forms, fn form ->
        form
        |> Map.from_struct()
        |> Map.delete(:version)
        |> Map.new(fn
          {:owner, owner} ->
            {"owner", Portable.id(owner)}

          {:kind, kind} ->
            {"kind", Atom.to_string(kind)}

          {:choices, choices} ->
            {"choices",
             Enum.map(choices, &%{"owner" => Portable.id(&1.owner), "value" => &1.value})}

          {key, value} ->
            {Atom.to_string(key), value}
        end)
      end)

    envelope = %{
      "protocol" => "blazex.dom-continuity/1",
      "transaction" => ReconciledSession.transaction(state.inner),
      "controls" => controls,
      "base_control_digest" => state.control_digest,
      "control_digest" => Codec.digest(controls)
    }

    {:ok, %{state | pending: Map.put(envelope, "digest", Codec.digest(envelope))}}
  rescue
    _ -> {:error, "limit"}
  catch
    {:protocol, code} -> {:error, code}
  end
end
