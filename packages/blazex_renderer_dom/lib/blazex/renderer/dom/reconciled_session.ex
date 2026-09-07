defmodule BlazeX.Renderer.DOM.ReconciledSession do
  @moduledoc """
  Acknowledgement-aware facade over the unchanged neutral renderer Session.
  accepted is the only committed session; pending is a provisional callback
  result. Returned immutable values must be threaded by the caller.
  """
  alias BlazeX.Renderer.{Context, Session}
  alias BlazeX.Renderer.DOM.{Incremental, Retained}
  defstruct accepted: nil, pending: nil, state: %Incremental{}

  def mount(output), do: mount(%__MODULE__{}, output)

  def mount(%__MODULE__{accepted: nil, pending: nil, state: state} = facade, output) do
    with :ok <- Retained.check_input(output),
         {:ok, proposal} <- Session.mount(Incremental, output),
         {:ok, context} <- Context.new(proposal.owner, 0, :mount),
         {:ok, backend_state, artifact} <- mount_attempt(state, proposal, output, context) do
      proposal = %{proposal | backend_state: backend_state, artifact: artifact}
      {:ok, %{facade | pending: proposal, state: backend_state}}
    end
  end

  def mount(_, _), do: {:error, "pending-transaction"}
  def update(facade, output), do: change(facade, :update, output)
  def replace(facade, output), do: change(facade, :replace, output)
  def dispose(%__MODULE__{state: %Incremental{disposed: true}} = facade), do: {:ok, facade}
  def dispose(facade), do: change(facade, :dispose, nil)
  def transaction(%__MODULE__{state: %Incremental{pending: nil}}), do: nil
  def transaction(%__MODULE__{state: state}), do: state.pending.transaction

  def acknowledge(%__MODULE__{} = facade, ack) do
    with {:ok, state, outcome} <- Incremental.acknowledge(facade.state, ack) do
      case outcome do
        :pending ->
          {:ok, %{facade | pending: %{facade.pending | backend_state: state}, state: state}}

        :committed ->
          {:ok,
           %{
             facade
             | accepted: %{facade.pending | backend_state: state},
               pending: nil,
               state: state
           }}

        :rejected ->
          accepted = if facade.accepted, do: %{facade.accepted | backend_state: state}, else: nil
          {:ok, %{facade | accepted: accepted, pending: nil, state: state}}
      end
    end
  end

  def acknowledge(_, _), do: {:error, "incompatible-state"}

  defp change(%__MODULE__{pending: pending}, _, _) when pending != nil,
    do: {:error, "pending-transaction"}

  defp change(%__MODULE__{state: %Incremental{disposed: true}}, _, _),
    do: {:error, "disposed-root"}

  defp change(%__MODULE__{accepted: %Session{} = accepted} = facade, stage, output) do
    with :ok <- if(stage == :dispose, do: :ok, else: Retained.check_input(output)),
         {:ok, proposal} <-
           if(stage == :dispose,
             do: Session.dispose(accepted),
             else: apply(Session, stage, [accepted, output])
           ) do
      {:ok, %{facade | pending: proposal, state: proposal.backend_state}}
    end
  end

  defp change(_, _, _), do: {:error, "unmounted"}

  defp mount_attempt(%Incremental{attempt: 1}, proposal, _, _),
    do: {:ok, proposal.backend_state, proposal.artifact}

  defp mount_attempt(state, _, output, context),
    do: Incremental.retry_mount(state, output, context)
end
