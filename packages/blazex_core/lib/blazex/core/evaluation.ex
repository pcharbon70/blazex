defmodule BlazeX.Core.Evaluation do
  @moduledoc """
  Accepted output and state from one experimental component evaluation.
  """

  alias BlazeX.Core.Identity

  @enforce_keys [:component, :mode, :identity, :props, :state, :output, :revision]
  defstruct [:component, :mode, :identity, :props, :state, :output, :revision]

  @type t :: %__MODULE__{
          component: module(),
          mode: :pure | :stateful,
          identity: Identity.t(),
          props: map(),
          state: term() | nil,
          output: term(),
          revision: non_neg_integer()
        }
end
