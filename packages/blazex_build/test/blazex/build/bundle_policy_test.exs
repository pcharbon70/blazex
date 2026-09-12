defmodule BlazeX.Build.BundlePolicyTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.BundlePolicy

  test "normalizes features and declarations deterministically" do
    left = BundlePolicy.new!(policy())
    right = BundlePolicy.new!(update_in(policy()["startup_modules"], &Enum.reverse/1))
    assert left.sha256 == right.sha256
  end

  test "rejects unknown fields, overlap, duplicate ownership, and invalid limits" do
    assert_raise ArgumentError, fn -> BundlePolicy.new!(Map.put(policy(), "extra", true)) end

    overlap = put_in(policy(), ["features", Access.at(0), "modules"], ["Elixir.App.Boot"])
    assert_raise ArgumentError, ~r/startup/, fn -> BundlePolicy.new!(overlap) end

    duplicate = update_in(policy()["features"], &(&1 ++ &1))
    assert_raise ArgumentError, ~r/duplicate/, fn -> BundlePolicy.new!(duplicate) end

    overflow = put_in(policy(), ["limits", "max_bundles"], 1)
    assert_raise ArgumentError, ~r/limits/, fn -> BundlePolicy.new!(overflow) end
  end

  def policy do
    %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.bundles/1",
      "base_bundle_id" => "base",
      "startup_modules" => ["Elixir.App.Boot", "Elixir.App.Host"],
      "features" => [
        %{"id" => "counter", "entrypoint_ids" => ["counter"], "modules" => ["Elixir.App.Counter"]}
      ],
      "limits" => %{
        "max_bundles" => 4,
        "max_inputs" => 10,
        "max_input_bytes" => 100,
        "max_total_bytes" => 200
      }
    }
  end
end
