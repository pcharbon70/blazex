defmodule BlazeX.Core.Evaluation do
  @moduledoc """
  Accepted output and state from one experimental component evaluation.
  """

  alias BlazeX.Core.Identity

  @enforce_keys [
    :component,
    :mode,
    :identity,
    :props,
    :state,
    :output,
    :revision,
    :last_event_sequence
  ]
  defstruct [
    :component,
    :mode,
    :identity,
    :props,
    :state,
    :output,
    :revision,
    :last_event_sequence
  ]

  @type t :: %__MODULE__{
          component: module(),
          mode: :pure | :stateful,
          identity: Identity.t(),
          props: map(),
          state: term() | nil,
          output: term(),
          revision: non_neg_integer(),
          last_event_sequence: non_neg_integer()
        }
end
