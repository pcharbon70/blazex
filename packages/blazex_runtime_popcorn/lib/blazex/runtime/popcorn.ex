defmodule BlazeX.Runtime.Popcorn do
  @moduledoc """
  Experimental BH-01 adapter boundary for the pinned FissionVM/Popcorn runtime.

  The values exposed here describe the disposable fixture-facing hooks that
  Phase 3 is allowed to exercise. They are not a stable framework runtime API,
  and they deliberately contain no browser, renderer, server-framework, or
  component semantics.
  """

  @typedoc "Experimental runtime-adapter hook used only by BH-01 fixtures."
  @type fixture_hook :: :boot_fixture | :dispatch_fixture_message | :dispose_fixture

  @doc "Returns the replaceable BH-01 adapter contract."
  @spec adapter_contract() :: map()
  def adapter_contract do
    %{
      status: :experimental_bh01,
      runtime: :fissionvm_popcorn,
      hooks: [:boot_fixture, :dispatch_fixture_message, :dispose_fixture],
      stable_public_api: false,
      owns_component_semantics: false
    }
  end
end
