defmodule BlazeX.Host.Browser do
  @moduledoc """
  Experimental ownership boundary for browser host lifecycle work.

  BH-03 Phase 4 keeps compatibility negotiation here while browser-side
  acquisition, startup, exact-compatible runtime sharing, and independent root
  queues live in `js/blazex_runtime`. It does not implement shutdown or provide
  a stable API.
  """

  alias BlazeX.Host.Browser.Compatibility
  alias BlazeX.Host.Browser.Lifecycle

  @doc "Returns the exact compatibility identities required by this host."
  @spec required_identities() :: map()
  defdelegate required_identities(), to: Compatibility

  @doc "Negotiates an observed identity map before artifact acquisition."
  @spec negotiate_compatibility(map() | [{String.t(), String.t()}]) ::
          {:ok, map()} | {:error, map()}
  defdelegate negotiate_compatibility(observed), to: Compatibility, as: :negotiate

  @doc "Returns the closed Phase 4 root lifecycle contract."
  @spec root_lifecycle_contract() :: map()
  defdelegate root_lifecycle_contract(), to: Lifecycle, as: :contract
end
