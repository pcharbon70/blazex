defmodule BlazeX.Build.BundlePlanTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.{BundlePlan, BundlePolicy}
  alias BlazeX.Build.BundlePolicyTest

  test "emits deterministic exact base and feature ownership" do
    policy = BundlePolicy.new!(BundlePolicyTest.policy())

    inputs = [
      input("Elixir.App.Boot", "base", "a"),
      input("Elixir.App.Host", "base", "b"),
      input("Elixir.App.Counter", "counter", "c")
    ]

    left = BundlePlan.plan!(inputs, policy)
    assert left == BundlePlan.plan!(Enum.reverse(inputs), policy)

    assert left["summary"] == %{
             "bundles" => 2,
             "features" => 1,
             "inputs" => 3,
             "input_bytes" => 3
           }

    assert Enum.find(left["bundles"], &(&1["id"] == "counter"))["modules"] == [
             "Elixir.App.Counter"
           ]
  end

  test "rejects missing, extra, duplicate, unknown, and conflicting declarations" do
    policy = BundlePolicy.new!(BundlePolicyTest.policy())
    base = [input("Elixir.App.Boot", "base", "a"), input("Elixir.App.Host", "base", "b")]
    feature = input("Elixir.App.Counter", "counter", "c")
    assert_raise ArgumentError, ~r/module set/, fn -> BundlePlan.plan!(base, policy) end

    assert_raise ArgumentError, ~r/module set/, fn ->
      BundlePlan.plan!([%{feature | "bundle_id" => "base"} | base], policy)
    end

    assert_raise ArgumentError, ~r/duplicate/, fn ->
      BundlePlan.plan!([feature, feature | base], policy)
    end

    assert_raise ArgumentError, ~r/unknown ownership/, fn ->
      BundlePlan.plan!([%{feature | "bundle_id" => "other"} | base], policy)
    end

    assert_raise ArgumentError, ~r/disagree/, fn ->
      BundlePlan.plan!([%{feature | "module" => "Elixir.App.Other"} | base], policy)
    end
  end

  test "rejects missing or feature-owned startup and scaling overflow" do
    policy = BundlePolicy.new!(BundlePolicyTest.policy())
    feature = input("Elixir.App.Counter", "counter", "c")

    assert_raise ArgumentError, ~r/startup/, fn ->
      BundlePlan.plan!([input("Elixir.App.Boot", "base", "a"), feature], policy)
    end

    large = input("Elixir.App.Host", "base", String.duplicate("x", 101))

    assert_raise ArgumentError, ~r/per-input/, fn ->
      BundlePlan.plan!([input("Elixir.App.Boot", "base", "a"), large, feature], policy)
    end
  end

  defp input(module, bundle, bytes),
    do: %{
      "label" => "bundle/#{module}.beam",
      "module" => module,
      "bundle_id" => bundle,
      "bytes" => bytes
    }
end
