defmodule BlazeX.Renderer.Context do
  @moduledoc """
  Versioned identity and sequencing context passed to a renderer backend.
  """

  alias BlazeX.Core.Identity

  @version 1
  @transitions [:mount, :update, :replace, :dispose]
  @enforce_keys [:version, :owner, :generation, :revision, :transition]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          version: 1,
          owner: Identity.t(),
          generation: pos_integer(),
          revision: non_neg_integer(),
          transition: :mount | :update | :replace | :dispose
        }

  @spec new(Identity.t(), non_neg_integer(), atom()) :: {:ok, t()} | {:error, atom()}
  def new(owner, revision, transition) do
    cond do
      not Identity.valid?(owner) ->
        {:error, :invalid_renderer_owner}

      not is_integer(revision) or revision < 0 ->
        {:error, :invalid_renderer_revision}

      transition not in @transitions ->
        {:error, :invalid_renderer_transition}

      true ->
        {:ok,
         %__MODULE__{
           version: @version,
           owner: owner,
           generation: owner.generation,
           revision: revision,
           transition: transition
         }}
    end
  end

  @spec transitions() :: [atom()]
  def transitions, do: @transitions
end
