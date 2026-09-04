defmodule BlazeX.Renderer.DOM.LiveViewBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Renderer.DOM.LiveView
  alias BlazeX.Renderer.DOM.LiveView.Compatibility

  @fixture Path.expand("../../../../fixtures/compatibility-contract.exs", __DIR__)

  test "exact pinned descriptor is eligible and can activate" do
    descriptor = fixture()
    assert {:ok, report} = Compatibility.probe(descriptor)
    assert report["versions"] == descriptor["versions"]
    assert report["surface_count"] == 7

    assert {:ok, state} = LiveView.activate(descriptor)
    assert LiveView.snapshot(state)["status"] == "active"
    assert state.capability["fallback"] == "standalone-dom"
  end

  test "configuration, version, field, surface, and malformed mismatch disable before activation" do
    descriptor = fixture()

    assert {:disabled, %{"reason" => "disabled-by-configuration"}} =
             LiveView.activate(descriptor, enabled: false)

    assert {:disabled, %{"reason" => "version-mismatch"}} =
             descriptor
             |> put_in(["versions", "phoenix_live_view"], "1.2.12")
             |> LiveView.activate()

    assert {:disabled, %{"reason" => "descriptor-fields-mismatch"}} =
             descriptor |> Map.put("unexpected", true) |> LiveView.activate()

    assert {:disabled, %{"reason" => "surface-set-mismatch"}} =
             descriptor |> update_in(["surfaces"], &Map.delete(&1, "diff")) |> LiveView.activate()

    assert {:disabled, %{"reason" => "surface-shape-mismatch"}} =
             descriptor |> put_in(["surfaces", "diff"], ["render/4"]) |> LiveView.activate()

    assert {:disabled, %{"reason" => "descriptor-invalid"}} = LiveView.activate(%{})
  end

  test "full and diff patches translate through the adapter-owned fixture boundary" do
    assert {:ok, state} = LiveView.activate(fixture())
    assert {:ok, full, state} = LiveView.apply_patch(state, patch(1, "full", %{"s" => ["hello"]}))
    assert full["sequence"] == 1
    assert full["payload"] == %{"s" => ["hello"]}

    assert {:ok, diff, state} = LiveView.apply_patch(state, patch(2, "diff", %{"0" => "world"}))
    assert diff["kind"] == "diff"
    assert LiveView.snapshot(state)["applied"] == 2
  end

  test "duplicate, stale, malformed, disconnect, reconnect, and disposal stay bounded" do
    assert {:ok, state} = LiveView.activate(fixture())
    assert {:ok, _, state} = LiveView.apply_patch(state, patch(1, "full", %{}))

    assert {:drop, %{"reason" => "patch-sequence-stale"}, state} =
             LiveView.apply_patch(state, patch(1, "diff", %{}))

    assert state.stale_drops == 1

    assert {:drop, %{"reason" => "patch-generation-stale"}, state} =
             LiveView.apply_patch(state, %{patch(2, "diff", %{}) | "generation" => 2})

    state = state |> LiveView.disconnect() |> LiveView.reconnect()
    assert LiveView.snapshot(state)["status"] == "awaiting_full"

    assert {:drop, %{"reason" => "full-patch-required"}, state} =
             LiveView.apply_patch(state, patch(2, "diff", %{}))

    assert {:ok, _, state} = LiveView.apply_patch(state, patch(2, "full", %{"reset" => true}))

    assert {:disabled, %{"reason" => "patch-envelope-invalid"}, disabled} =
             LiveView.apply_patch(state, %{"protocol" => "wrong"})

    assert LiveView.snapshot(disabled)["status"] == "disabled"

    disposed = LiveView.dispose(state)

    assert {:disabled, %{"reason" => "adapter-not-active"}, ^disposed} =
             LiveView.apply_patch(disposed, patch(3, "diff", %{}))
  end

  defp fixture do
    {descriptor, _binding} = Code.eval_file(@fixture)
    descriptor
  end

  defp patch(sequence, kind, payload) do
    %{
      "protocol" => "blazex.bh01.liveview-patch/0.1",
      "generation" => 1,
      "sequence" => sequence,
      "kind" => kind,
      "payload" => payload
    }
  end
end
