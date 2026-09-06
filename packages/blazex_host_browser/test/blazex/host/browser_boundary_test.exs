defmodule BlazeX.Host.BrowserBoundaryTest do
  use ExUnit.Case, async: true

  test "experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Host.Browser)
  end

  test "accepts only the exact compatibility identity table" do
    expected = BlazeX.Host.Browser.required_identities()

    assert {:ok,
            %{
              protocol: "blazex.compatibility-negotiation/1",
              decision: :compatible,
              identities: ^expected
            }} = BlazeX.Host.Browser.negotiate_compatibility(expected)
  end

  test "rejects missing, unknown, duplicate, malformed, and mismatched identities" do
    expected = BlazeX.Host.Browser.required_identities()

    assert {:error, %{class: :identity_mismatch, reason: :missing}} =
             expected
             |> Map.delete("renderer")
             |> BlazeX.Host.Browser.negotiate_compatibility()

    assert {:error, %{class: :identity_mismatch, reason: :unknown}} =
             expected
             |> Map.put("future_contract", "blazex.future/1")
             |> BlazeX.Host.Browser.negotiate_compatibility()

    duplicate = Map.to_list(expected) ++ [{"renderer", "blazex.renderer/1"}]

    assert {:error, %{class: :identity_mismatch, reason: :duplicate}} =
             BlazeX.Host.Browser.negotiate_compatibility(duplicate)

    assert {:error, %{class: :identity_mismatch, reason: :malformed}} =
             BlazeX.Host.Browser.negotiate_compatibility(%{"renderer" => "not-an-identity"})

    assert {:error,
            %{
              class: :identity_mismatch,
              reason: :mismatch,
              phase: :before_artifact_acquisition
            }} =
             expected
             |> Map.put("renderer", "blazex.renderer/2")
             |> BlazeX.Host.Browser.negotiate_compatibility()
  end

  test "publishes the closed independent-root lifecycle without runtime ownership" do
    contract = BlazeX.Host.Browser.root_lifecycle_contract()

    assert contract.protocol == "blazex.root-lifecycle/1"
    assert contract.max_roots_per_scope == 64

    assert contract.operations ==
             ["root.register", "root.mount", "root.update", "root.move", "root.dispose"]

    assert contract.serialization == :one_fifo_queue_per_root
    assert contract.cross_root_progress == :independent
    assert contract.runtime_owner == :runtime_registry
    refute contract.root_owns_runtime_release
  end
end
