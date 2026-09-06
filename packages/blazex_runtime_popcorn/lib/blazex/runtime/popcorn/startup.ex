defmodule BlazeX.Runtime.Popcorn.Startup do
  @moduledoc """
  Immutable startup descriptor for one experimental BH-03 runtime attempt.

  The descriptor binds the retained Popcorn artifact entrypoint and readiness
  signal. It does not start, share, recover, or shut down a runtime and owns no
  browser-root, renderer, component, or server behavior.
  """

  @descriptor %{
    "protocol" => "blazex.runtime-startup/1",
    "adapter_identity" => "blazex.popcorn-runtime-adapter/1",
    "engine" => "fissionvm-popcorn",
    "transport_protocol" => "blazex.runtime.frame/1",
    "memory_pages" => 256,
    "bundle_virtual_path" => "/bundle.avm",
    "entrypoint" => "Elixir.BlazeX.BH01.BrowserHost.Boot",
    "readiness_event" => "popcorn_app_ready",
    "required_features" => ["shared-memory", "threads"],
    "api_state" => "experimental-not-stable",
    "support_state" => "unsupported"
  }

  @doc "Returns the exact descriptor for an isolated Phase 3 startup attempt."
  @spec descriptor() :: map()
  def descriptor, do: @descriptor
end
