defmodule BlazeX.Host.Browser do
  @moduledoc """
  Experimental ownership boundary for browser host lifecycle work.

  BH-03 Phase 3 keeps compatibility negotiation here while browser-side
  acquisition and isolated startup live in `js/blazex_runtime`. It does not
  share runtimes, register roots, or provide a stable API.
  """

  alias BlazeX.Host.Browser.Compatibility

  @doc "Returns the exact compatibility identities required by this host."
  @spec required_identities() :: map()
  defdelegate required_identities(), to: Compatibility

  @doc "Negotiates an observed identity map before artifact acquisition."
  @spec negotiate_compatibility(map() | [{String.t(), String.t()}]) ::
          {:ok, map()} | {:error, map()}
  defdelegate negotiate_compatibility(observed), to: Compatibility, as: :negotiate
end
