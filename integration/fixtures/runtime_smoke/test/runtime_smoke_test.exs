defmodule BlazeX.BH01.RuntimeSmokeTest do
  use ExUnit.Case, async: false

  test "disposable fixture completes its bounded BEAM lifecycle" do
    assert :ok = BlazeX.BH01.RuntimeSmoke.start()
  end
end
