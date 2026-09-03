defmodule BlazeX.PhoenixBoundaryTest do
  use ExUnit.Case, async: true

  test "server-adapter module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Phoenix)
  end
end
