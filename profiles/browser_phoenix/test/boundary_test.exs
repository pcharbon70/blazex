defmodule BlazeXBrowserPhoenix.BoundaryTest do
  use ExUnit.Case, async: true

  test "profile boundary and feasibility endpoint modules compile" do
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.CompositionBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.EndpointBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.TeardownBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.Endpoint)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.AssetPlug)
  end
end
