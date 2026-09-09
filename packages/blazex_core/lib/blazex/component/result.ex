defmodule BlazeX.Component.Result do
  @moduledoc """
  Closed candidate return algebra. Never executes actions or commits state.
  Output is a tagged, portable semantic candidate, not a validated UI document.
  Typed actions are bounded intent; authority, providers and execution are Phase 8.
  """
  alias BlazeX.Component.{Contract, Input}
  @reasons [:invalid_input, :unsupported, :failed, :cancelled]
  @kinds [:effect, :command, :message, :timer, :release]
  @max_actions 128
  @type candidate ::
          :ok
          | :no_change
          | {:state, term()}
          | {:output, {:semantic, 1, map()}}
          | {:actions, term(), [BlazeX.Component.Action.t() | {atom(), binary(), term()}]}
          | {:stop, atom()}
          | {:retry_request, atom()}
          | {:rejected, atom()}

  @spec validate(atom(), atom(), term()) :: :ok | {:error, map()}
  def validate(role, callback, result) do
    {form, valid} = form(result)

    if valid and form in Contract.result_forms(role, callback),
      do: :ok,
      else: Input.error(:invalid_result)
  end

  defp form(:ok), do: {:ok, true}
  defp form(:no_change), do: {:no_change, true}
  defp form({:state, state}), do: {:state, Input.portable?(state)}

  defp form({:output, {:semantic, 1, tree}}),
    do: {:output, is_map(tree) and Input.portable?(tree)}

  defp form({:actions, state, actions}),
    do: {:actions, Input.portable?(state) and actions?(actions)}

  defp form({:stop, reason}), do: {:stop, reason in [:normal, :cancelled, :failed]}

  defp form({:retry_request, reason}),
    do: {:retry_request, reason in [:transient, :dependency_unavailable]}

  defp form({:rejected, reason}), do: {:rejected, reason in @reasons}
  defp form(_result), do: {:invalid, false}

  defp actions?(actions) do
    Input.portable?(actions) and is_list(actions) and length(actions) in 1..@max_actions and
      Enum.all?(actions, fn
        %{version: 1} = action ->
          BlazeX.Component.Action.valid?(action)

        {kind, id, payload} ->
          kind in @kinds and is_binary(id) and byte_size(id) in 1..128 and
            Input.portable?(payload)

        _ ->
          false
      end)
  end
end
