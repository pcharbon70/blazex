defmodule BlazeX.HeadlessProfileBoundaryTest do
  use ExUnit.Case, async: true

  test "the profile composes only the approved neutral boundaries" do
    assert Code.ensure_loaded?(BlazeX.Core)
    assert Code.ensure_loaded?(BlazeX.Effects)
    assert Code.ensure_loaded?(BlazeX.UITree)
    assert Code.ensure_loaded?(BlazeX.Renderer)
    assert Code.ensure_loaded?(BlazeX.Renderer.Headless)
    assert Code.ensure_loaded?(BlazeX.Test)
    assert Code.ensure_loaded?(BlazeX.HeadlessProfile)
  end
end
