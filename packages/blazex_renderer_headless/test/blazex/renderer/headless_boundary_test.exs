defmodule BlazeX.Renderer.HeadlessBoundaryTest do
  use ExUnit.Case, async: true

  test "the headless implementation boundary compiles over neutral contracts" do
    assert Code.ensure_loaded?(BlazeX.Renderer)
    assert Code.ensure_loaded?(BlazeX.Renderer.Headless)
  end
end
