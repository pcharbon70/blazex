defmodule BlazeX.Runtime.Popcorn do
  @moduledoc """
  Experimental adapter boundary for the pinned FissionVM/Popcorn runtime.

  The retained BH-01 hooks and BH-03 compatibility/startup descriptors are not
  a stable framework runtime API. They deliberately contain no browser,
  renderer, server-framework, root, or component semantics.
  """

  alias BlazeX.Runtime.Popcorn.{Identity, Startup}

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

  @doc "Returns the reusable BH-03 compatibility descriptor."
  @spec compatibility_descriptor() :: map()
  defdelegate compatibility_descriptor(), to: Identity

  @doc "Returns the immutable descriptor for one isolated BH-03 startup attempt."
  @spec startup_descriptor() :: map()
  defdelegate startup_descriptor(), to: Startup, as: :descriptor
end
