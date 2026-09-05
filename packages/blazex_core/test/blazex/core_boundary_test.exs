defmodule BlazeX.CoreBoundaryTest do
  use ExUnit.Case, async: true

  test "the experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Core)
  end
end
