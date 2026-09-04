defmodule BlazeXBrowserPhoenix.BoundaryTest do
  use ExUnit.Case, async: true

  test "profile boundary and feasibility endpoint modules compile" do
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.CompositionBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.EndpointBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.TeardownBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.Endpoint)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.AssetPlug)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.ControlPlug)
    assert Code.ensure_loaded?(BlazeX.Phoenix.BH01.FixtureAuthority)
    assert Code.ensure_loaded?(BlazeX.Renderer.DOM.LiveView)
  end

  test "optional LiveView adapter activates only for the exact compatibility descriptor" do
    descriptor = BlazeX.Renderer.DOM.LiveView.Compatibility.expected_descriptor()

    assert {:ok, state} = BlazeX.Renderer.DOM.LiveView.activate(descriptor)
    assert BlazeX.Renderer.DOM.LiveView.snapshot(state)["status"] == "active"

    assert {:disabled, %{"fallback" => "standalone-dom", "reason" => "version-mismatch"}} =
             descriptor
             |> put_in(["versions", "local_live_view"], "0.2.0")
             |> BlazeX.Renderer.DOM.LiveView.activate()
  end
end
