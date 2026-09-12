defmodule BlazeX.Build.PayloadPolicyTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.PayloadPolicy

  test "accepts the closed-world bounded policy" do
    policy = PayloadPolicy.new!(policy())
    assert policy.id == "test.payload/1"
    assert policy.compression["repetitions"] == 3
    assert policy.roles["feature-bundle"]["owner"] == "application"
  end

  test "rejects incomplete roles, duplicate budgets, and unsafe compression" do
    assert_raise ArgumentError, fn -> PayloadPolicy.new!(put_in(policy(), ["roles"], %{})) end
    duplicate = update_in(policy(), ["budgets"], &(&1 ++ &1))
    assert_raise ArgumentError, fn -> PayloadPolicy.new!(duplicate) end

    assert_raise ArgumentError, fn ->
      PayloadPolicy.new!(put_in(policy(), ["compression", "quality"], 5))
    end
  end

  def policy do
    roles =
      for role <-
            ~w(build-manifest document runtime-module runtime-wasm application-bundle browser-host feature-bundle reachability-report client-safety-report compatibility-report secret-audit-report license-inventory-report bundle-plan-report),
          into: %{} do
        exposure =
          if String.ends_with?(role, "report"), do: "private-build-evidence", else: "public"

        owner = if exposure == "public", do: "application", else: "build-evidence"
        {role, %{"owner" => owner, "exposure" => exposure}}
      end

    %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.payload/1",
      "compression" => %{
        "algorithm" => "brotli",
        "implementation" => "node-zlib",
        "quality" => 11,
        "repetitions" => 3
      },
      "roles" => roles,
      "budgets" => [
        %{
          "id" => "application-brotli",
          "owner" => "application",
          "metric" => "brotli_bytes",
          "direction" => "at-most",
          "threshold" => 1_000
        }
      ],
      "limits" => %{
        "max_artifacts" => 64,
        "max_public_bytes" => 1_000_000,
        "max_role_length" => 64,
        "max_owner_length" => 64
      }
    }
  end
end
