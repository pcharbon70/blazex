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

  test "publishes registry-owned bounded shutdown without granting roots runtime ownership" do
    contract = BlazeX.Host.Browser.root_lifecycle_contract()

    assert contract.protocol == "blazex.root-lifecycle/1"
    assert contract.max_roots_per_scope == 64

    assert contract.operations ==
             ["root.register", "root.mount", "root.update", "root.move", "root.dispose"]

    assert contract.serialization == :one_fifo_queue_per_root
    assert contract.cross_root_progress == :independent
    assert contract.runtime_owner == :runtime_registry
    refute contract.root_owns_runtime_release

    assert contract.runtime_states ==
             [:starting, :ready, :stopping, :stopped, :recovering, :failed, :fallback]

    assert contract.shutdown == %{
             protocol: "blazex.runtime-shutdown/1",
             operation: "runtime.shutdown",
             acknowledgement: [:scope_id, :runtime_generation],
             default_timeout_ms: 5_000,
             max_timeout_ms: 10_000,
             release: :registry_owned_exactly_once,
             terminal_record: :stopped_tombstone
           }

    assert contract.runtime_loss == %{
             protocol: "blazex.runtime-loss/1",
             acknowledgement: [:scope_id, :runtime_generation],
             stale_report: :reject_without_mutation,
             max_replacements: 1,
             replacement_delay_ms: 100,
             root_replay: :same_handles_all_or_nothing
           }

    assert contract.fallback.presentation == :non_dom_decision_only
    refute contract.fallback.partial_activation
    assert contract.fallback.classes["identity-mismatch"] == "deployment-action"
    assert contract.fallback.classes["unsupported-prerequisite"] == "static-content"
  end
end
