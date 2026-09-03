defmodule BlazeX.Runtime.PopcornBoundaryTest do
  use ExUnit.Case, async: true

  test "experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Runtime.Popcorn)
  end

  test "adapter exposes only disposable fixture hooks" do
    assert %{
             status: :experimental_bh01,
             runtime: :fissionvm_popcorn,
             hooks: [:boot_fixture, :dispatch_fixture_message, :dispose_fixture],
             stable_public_api: false,
             owns_component_semantics: false
           } = BlazeX.Runtime.Popcorn.adapter_contract()
  end
end
