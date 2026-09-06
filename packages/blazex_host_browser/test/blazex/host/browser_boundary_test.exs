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
end
