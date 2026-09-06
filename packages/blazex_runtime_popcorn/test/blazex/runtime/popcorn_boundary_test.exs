defmodule BlazeX.Runtime.PopcornBoundaryTest do
  use ExUnit.Case, async: true

  test "experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Runtime.Popcorn)
  end

  test "adapter exposes only disposable fixture hooks" do
    assert %{
             status: :experimental_bh01,
             runtime: :fissionvm_popcorn,
             hooks: [:boot_fixture, :dispatch_fixture_message, :dispose_fixture],
             stable_public_api: false,
             owns_component_semantics: false
           } = BlazeX.Runtime.Popcorn.adapter_contract()
  end

  test "publishes a reusable compatibility identity without lifecycle behavior" do
    assert %{
             "identity" => "blazex.popcorn-runtime-adapter/1",
             "engine" => "fissionvm-popcorn",
             "compatible_browser_host" => "blazex.browser-host/1",
             "compatible_runtime_loader" => "blazex.browser-runtime-loader/1",
             "compatible_profile_manifest" => "blazex.browser-profile-manifest/1",
             "compatible_root_lifecycle" => "blazex.browser-root-lifecycle/1",
             "artifact_roles" => ["runtime-module", "runtime-wasm", "application-bundle"],
             "api_state" => "experimental-not-stable",
             "support_state" => "unsupported"
           } = BlazeX.Runtime.Popcorn.compatibility_descriptor()
  end
end
