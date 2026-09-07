defmodule BlazeX.Renderer.DOM.Incremental do
  @moduledoc """
  Experimental neutral-backend callbacks producing pending v2 transactions.
  Only acknowledge/2 may promote a projection. Use ReconciledSession to keep
  the neutral session's provisional metadata behind the same acknowledgement.
  """
  @behaviour BlazeX.Renderer.Backend
  alias BlazeX.Renderer.{Artifact, Capabilities, Context}
  alias BlazeX.Renderer.DOM.{ProtocolV2, Reconciler, Retained}

  defstruct version: 1,
            accepted: nil,
            pending: nil,
            revision: 0,
            attempt: 1,
            owner: nil,
            neutral_revision: nil,
            disposed: false,
            last_terminal: nil

  @impl true
  def capabilities, do: Capabilities.full()
  @impl true
  def mount(output, context), do: propose(%__MODULE__{}, output, context, :mount)
  @impl true
  def update(state, output, context), do: propose(state, output, context, :update)
  @impl true
  def replace(state, output, context), do: propose(state, output, context, :replace)
  @impl true
  def dispose(state, context), do: propose(state, nil, context, :dispose)

  def retry_mount(%__MODULE__{accepted: nil} = state, output, context),
    do: propose(state, output, context, :mount)

  defp propose(
         %__MODULE__{version: 1, disposed: false, pending: nil} = state,
         output,
         context,
         stage
       ) do
    with :ok <- valid_state(state),
         :ok <- valid_context(state, context, stage),
         {:ok, next} <- projection(output, context),
         {:ok, tx, scope, decision} <-
           Reconciler.transaction(
             state.accepted,
             next,
             kind(stage),
             state.revision,
             state.attempt
           ) do
      pending = %{
        projection: next,
        transaction: tx,
        context: scope,
        semantic_context: context,
        decision: decision,
        progress: 0
      }

      updated = %{state | pending: pending, attempt: state.attempt + 1}
      {:ok, updated, %Artifact{version: 1, format: :dom_transaction_v2, value: tx}}
    end
  end

  defp propose(%__MODULE__{disposed: true}, _, _, _), do: {:error, "disposed-root"}

  defp propose(%__MODULE__{pending: pending}, _, _, _) when pending != nil,
    do: {:error, "pending-transaction"}

  defp propose(_, _, _, _), do: {:error, "incompatible-state"}

  def acknowledge(%__MODULE__{disposed: true}, _), do: {:error, "disposed-root"}

  def acknowledge(%__MODULE__{pending: nil, last_terminal: last}, ack) do
    if is_map(ack) and last != nil and ack["transaction_id"] == last,
      do: {:error, "duplicate"},
      else: {:error, "acknowledgement-mismatch"}
  end

  def acknowledge(%__MODULE__{version: 1, pending: pending} = state, ack) do
    with :ok <- valid_state(state),
         true <- valid_pending?(state),
         scope =
           Map.put(pending.context, "transaction", Reconciler.attempt_header(pending.transaction)),
         {:ok, _} <- ProtocolV2.new(ack, scope) do
      cond do
        ack["record"] != "ack" ->
          {:error, "acknowledgement-mismatch"}

        ack["state"] in ~w(preflight accepted) ->
          rank = if ack["state"] == "preflight", do: 1, else: 2

          if rank > pending.progress,
            do: {:ok, %{state | pending: %{pending | progress: rank}}, :pending},
            else: {:error, "acknowledgement-mismatch"}

        ack["state"] in ~w(committed disposed) ->
          context = pending.semantic_context

          {:ok,
           %{
             state
             | accepted: pending.projection,
               pending: nil,
               revision: ack["target_revision"],
               owner: context.owner,
               neutral_revision: context.revision,
               disposed: ack["state"] == "disposed",
               last_terminal: ack["transaction_id"]
           }, :committed}

        ack["state"] in ~w(rejected rolled-back) ->
          {:ok, %{state | pending: nil, last_terminal: ack["transaction_id"]}, :rejected}

        true ->
          {:error, "replacement-not-authorized"}
      end
    else
      _ -> {:error, "acknowledgement-mismatch"}
    end
  end

  def acknowledge(_, _), do: {:error, "incompatible-state"}

  defp projection(nil, %Context{transition: :dispose}), do: {:ok, nil}
  defp projection(output, context), do: Retained.from_output(output, context)
  defp kind(:mount), do: "initial"
  defp kind(:update), do: "patch"
  defp kind(:replace), do: "replace"
  defp kind(:dispose), do: "dispose"

  defp valid_context(state, %Context{} = context, stage) do
    valid = Context.new(context.owner, context.revision, stage) == {:ok, context}

    transition =
      case stage do
        :mount ->
          state.accepted == nil and state.owner == nil and state.revision == 0 and
            context.revision == 0

        :update ->
          state.accepted != nil and state.owner == context.owner and
            context.revision == state.neutral_revision + 1

        :replace ->
          state.accepted != nil and
            %{state.owner | generation: state.owner.generation + 1} == context.owner and
            context.revision == 0

        :dispose ->
          state.accepted != nil and state.owner == context.owner and
            context.revision == state.neutral_revision
      end

    if valid and transition, do: :ok, else: {:error, "incompatible-state"}
  end

  defp valid_context(_, _, _), do: {:error, "incompatible-state"}

  defp valid_state(state) do
    valid =
      is_integer(state.revision) and state.revision >= 0 and
        state.revision < 9_007_199_254_740_991 and
        is_integer(state.attempt) and state.attempt in 1..9_007_199_254_740_992 and
        if state.accepted == nil,
          do: state.owner == nil and state.neutral_revision == nil and state.revision == 0,
          else:
            Retained.validate(state.accepted) == :ok and state.accepted.owner == state.owner and
              is_integer(state.neutral_revision) and state.neutral_revision >= 0

    if valid, do: :ok, else: {:error, "incompatible-state"}
  end

  defp valid_pending?(
         %{
           pending: %{
             projection: projection,
             transaction: tx,
             context: scope,
             semantic_context: context,
             decision: decision,
             progress: progress
           }
         } = state
       ) do
    progress in 0..2 and valid_context(state, context, context.transition) == :ok and
      Reconciler.transaction(
        state.accepted,
        projection,
        kind(context.transition),
        state.revision,
        state.attempt - 1
      ) == {:ok, tx, scope, decision}
  rescue
    _ -> false
  end

  defp valid_pending?(_), do: false
end
