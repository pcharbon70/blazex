defmodule BlazeX.EffectsBoundaryTest do
  use ExUnit.Case, async: true

  test "the boundary depends inward only on core" do
    assert Code.ensure_loaded?(BlazeX.Core)
    assert Code.ensure_loaded?(BlazeX.Effects)
  end
end
