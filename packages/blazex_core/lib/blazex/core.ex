defmodule BlazeX.Core do
  @moduledoc """
  Experimental host-neutral component-kernel boundary.

  BH-02 Phase 2 defines deterministic component identity and pure/stateful
  evaluation here. Phase 3 adds semantic event envelopes and atomic stateful
  dispatch. Effects stay in `blazex_effects`; process lifecycle, messages,
  commands, ambient rerendering, and disposal remain outside this phase.
  """
end
