defmodule BlazeX.Core.Diagnostic do
  @moduledoc """
  Stable evaluation failure data that excludes raw callback values.
  """

  @enforce_keys [:code, :stage, :component]
  defstruct [:code, :stage, :component, :detail]

  @type code ::
          :invalid_component
          | :invalid_identity
          | :invalid_props
          | :invalid_evaluation
          | :missing_callback
          | :invalid_mode
          | :callback_rejected
          | :callback_failed
          | :invalid_callback_result
          | :invalid_state
          | :generation_exhausted
          | :invalid_semantic_output
          | :root_identity_mismatch

  @type stage :: :contract | :mount | :update | :replace | :init | :render
  @type t :: %__MODULE__{
          code: code(),
          stage: stage(),
          component: module() | nil,
          detail: atom() | nil
        }
end
