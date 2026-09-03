defmodule BlazeX.Renderer.DOM.LiveViewBoundaryTest do
  use ExUnit.Case, async: true

  test "optional-adapter module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Renderer.DOM.LiveView)
  end
end
