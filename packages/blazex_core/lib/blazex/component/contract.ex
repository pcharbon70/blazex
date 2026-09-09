defmodule BlazeX.Component.Contract do
  @moduledoc """
  Candidate role and callback inventory. This module performs no scheduling.
  All callbacks have one immutable input envelope; a callback name is also its
  transition name. Optional callbacks are absent, not silently synthesized.
  """

  @spec version() :: binary()
  def version, do: "0.1.0-bh05-candidate"

  @spec roles() :: [atom()]
  def roles, do: [:pure, :stateful, :root]

  @spec callbacks(atom()) :: %{required: [atom()], optional: [atom()]} | :error
  def callbacks(:pure), do: %{required: [:render], optional: []}

  def callbacks(:stateful) do
    %{
      required: [:init, :render],
      optional: [:update, :handle_event, :handle_info, :replace, :dispose]
    }
  end

  def callbacks(:root) do
    %{
      required: [:mount, :render],
      optional: [
        :update,
        :handle_event,
        :handle_info,
        :commit_ack,
        :effect_result,
        :failure,
        :retry,
        :replace,
        :terminate
      ]
    }
  end

  def callbacks(_role), do: :error

  @spec callback?(atom(), atom()) :: boolean()
  def callback?(role, callback) do
    case callbacks(role) do
      %{required: required, optional: optional} -> callback in (required ++ optional)
      :error -> false
    end
  end

  @spec result_forms(atom(), atom()) :: [atom()]
  def result_forms(role, callback) do
    if callback?(role, callback) do
      case callback do
        :render ->
          [:output, :rejected]

        name when name in [:init, :mount] ->
          [:state, :rejected]

        name when name in [:dispose, :terminate] ->
          [:ok, :rejected]

        name when name in [:failure, :retry] ->
          [:no_change, :state, :actions, :stop, :retry_request, :rejected]

        _ ->
          [:no_change, :state, :actions, :stop, :rejected]
      end
    else
      []
    end
  end
end
