defmodule BlazeX.TestBoundaryTest do
  use ExUnit.Case, async: true

  test "test support compiles over the neutral contracts" do
    assert Code.ensure_loaded?(BlazeX.Renderer)
    assert Code.ensure_loaded?(BlazeX.Test)
  end
end
