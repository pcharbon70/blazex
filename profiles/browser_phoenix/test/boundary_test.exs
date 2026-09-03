defmodule BlazeXBrowserPhoenix.BoundaryTest do
  use ExUnit.Case, async: true

  test "profile boundary modules compile without dependencies" do
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.CompositionBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.EndpointBoundary)
    assert Code.ensure_loaded?(BlazeXBrowserPhoenix.TeardownBoundary)
  end
end
