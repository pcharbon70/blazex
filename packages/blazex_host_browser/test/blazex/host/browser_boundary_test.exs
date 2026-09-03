defmodule BlazeX.Host.BrowserBoundaryTest do
  use ExUnit.Case, async: true

  test "experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Host.Browser)
  end
end
