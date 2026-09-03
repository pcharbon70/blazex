defmodule BlazeX.Runtime.PopcornBoundaryTest do
  use ExUnit.Case, async: true

  test "experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Runtime.Popcorn)
  end
end
