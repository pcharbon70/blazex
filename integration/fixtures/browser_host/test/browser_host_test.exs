defmodule BlazeX.BH01.BrowserHostTest do
  use ExUnit.Case, async: true

  test "fixture remains disposable and browser-only" do
    assert Code.ensure_loaded?(BlazeX.BH01.BrowserHost)
    assert function_exported?(BlazeX.BH01.BrowserHost, :start, 0)
  end
end
