defmodule BlazeX.Renderer.DOMBoundaryTest do
  use ExUnit.Case, async: true

  test "standalone experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Renderer.DOM)
  end
end
