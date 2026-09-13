defmodule BlazeXBrowserPhoenix.BoundaryTest do
  use ExUnit.Case, async: true

  test "profile boundary and feasibility endpoint modules compile" do
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.CompositionBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.EndpointBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.TeardownBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.Endpoint)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.AssetPlug)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.BootstrapPlug)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.DeliveryConfig)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.SessionPlug)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.AdmissionPlug)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.ControlPlug)
    assert Code.ensure_loaded?(BlazeX.Phoenix.BH01.FixtureAuthority)
    assert Code.ensure_loaded?(BlazeX.Phoenix.StaticDelivery)
    assert Code.ensure_loaded?(BlazeX.Phoenix.PublicBootstrap)
    assert Code.ensure_loaded?(BlazeX.Phoenix.SessionRegistry)
    assert Code.ensure_loaded?(BlazeX.Phoenix.CommandAdmission)
  end

  test "active profile excludes deferred LiveView and LocalLiveView dependencies" do
    dependencies =
      Mix.Project.config()
      |> Keyword.fetch!(:deps)
      |> Enum.map(&elem(&1, 0))

    refute :blazex_renderer_dom_liveview in dependencies
    refute :phoenix_live_view in dependencies
    refute :local_live_view in dependencies
  end
end
