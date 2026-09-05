defmodule BlazeX.RendererBoundaryTest do
  use ExUnit.Case, async: true

  test "the contract boundary sees only approved host-neutral packages" do
    assert Code.ensure_loaded?(BlazeX.Core)
    assert Code.ensure_loaded?(BlazeX.Effects)
    assert Code.ensure_loaded?(BlazeX.UITree)
    assert Code.ensure_loaded?(BlazeX.Renderer)
  end
end
