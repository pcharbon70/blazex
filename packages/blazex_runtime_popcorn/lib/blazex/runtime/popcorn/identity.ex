defmodule BlazeX.Runtime.Popcorn.Identity do
  @moduledoc """
  Versioned compatibility identity for the experimental Popcorn adapter.

  This descriptor is data only. It neither acquires artifacts nor starts a
  runtime, and it owns no browser-root, renderer, component, or server behavior.
  """

  @descriptor %{
    "identity" => "blazex.popcorn-runtime-adapter/1",
    "engine" => "fissionvm-popcorn",
    "compatible_browser_host" => "blazex.browser-host/1",
    "compatible_runtime_loader" => "blazex.browser-runtime-loader/1",
    "compatible_profile_manifest" => "blazex.browser-profile-manifest/1",
    "compatible_root_lifecycle" => "blazex.browser-root-lifecycle/1",
    "artifact_roles" => ["runtime-module", "runtime-wasm", "application-bundle"],
    "api_state" => "experimental-not-stable",
    "support_state" => "unsupported"
  }

  @doc "Returns the exact compatibility descriptor owned by this adapter."
  @spec compatibility_descriptor() :: map()
  def compatibility_descriptor, do: @descriptor
end
