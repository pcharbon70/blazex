defmodule BlazeX.Build.CompatibilityTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{
    Compatibility,
    CompatibilityError,
    CompatibilityProfile,
    CompatibilityRequirements
  }

  test "matches exact runtime, protocols, and features deterministically" do
    one = Compatibility.evaluate!(profile(), requirements())
    two = Compatibility.evaluate!(profile(reversed: true), requirements(reversed: true))
    assert one == two
    assert one["compatible"]
    assert one["violations"] == []

    assert one["summary"] == %{
             "feature_requirements" => 2,
             "matched" => 7,
             "protocol_requirements" => 2,
             "runtime_requirements" => 3,
             "violations" => 0
           }

    assert one["unused_profile"] == %{"features" => ["timers"], "protocols" => ["unused"]}
  end

  test "canonical hashes change with semantic input and not ordering" do
    assert profile().sha256 == profile(reversed: true).sha256
    assert requirements().sha256 == requirements(reversed: true).sha256
    refute profile(version: "0.6.7").sha256 == profile().sha256
    refute requirements(features: ["browser-dom"]).sha256 == requirements().sha256
  end

  test "rejects each runtime field mismatch" do
    for {field, value} <- [{"id", "other"}, {"version", "0.6.5"}, {"abi", "atomvm.avm/2"}] do
      changed = Map.put(raw_profile()["runtime"], field, value)

      error =
        assert_raise CompatibilityError, fn ->
          Compatibility.evaluate!(profile(runtime: changed), requirements())
        end

      assert Exception.message(error) =~ "runtime:#{field}"
    end
  end

  test "rejects missing and wrong protocol versions" do
    for protocols <- [
          [%{"id" => "browser-host", "version" => "1"}],
          [
            %{"id" => "browser-host", "version" => "2"},
            %{"id" => "semantic-tree", "version" => "1"}
          ]
        ] do
      assert_raise CompatibilityError, ~r/protocol:/, fn ->
        Compatibility.evaluate!(profile(protocols: protocols), requirements())
      end
    end
  end

  test "rejects missing and explicitly unsupported features" do
    missing = Enum.reject(raw_profile()["features"], &(&1["id"] == "atomvm-bundle"))

    unsupported =
      Enum.map(raw_profile()["features"], fn row ->
        if row["id"] == "atomvm-bundle", do: %{row | "state" => "unsupported"}, else: row
      end)

    for features <- [missing, unsupported] do
      assert_raise CompatibilityError, ~r/feature:atomvm-bundle/, fn ->
        Compatibility.evaluate!(profile(features: features), requirements())
      end
    end
  end

  test "rejects unknown fields, duplicates, malformed values, and untyped inputs" do
    assert_raise ArgumentError, ~r/unknown fields/, fn ->
      raw_profile() |> Map.put("extra", true) |> CompatibilityProfile.new!()
    end

    duplicate = [hd(raw_profile()["protocols"]) | raw_profile()["protocols"]]

    assert_raise ArgumentError, ~r/duplicate compatibility protocol/, fn ->
      raw_profile() |> Map.put("protocols", duplicate) |> CompatibilityProfile.new!()
    end

    assert_raise ArgumentError, ~r/feature is invalid/, fn ->
      raw_profile()
      |> put_in(["features", Access.at(0), "reason"], "bad\nreason")
      |> CompatibilityProfile.new!()
    end

    assert_raise ArgumentError, fn -> Compatibility.evaluate!(%{}, %{}) end
  end

  defp profile(options \\ []), do: raw_profile(options) |> CompatibilityProfile.new!()

  defp requirements(options \\ []),
    do: raw_requirements(options) |> CompatibilityRequirements.new!()

  defp raw_profile(options \\ []) do
    runtime =
      Keyword.get(options, :runtime, %{
        "id" => "atomvm-wasm",
        "version" => Keyword.get(options, :version, "0.6.6-dev"),
        "abi" => "atomvm.avm/1"
      })

    protocols =
      Keyword.get(options, :protocols, [
        %{"id" => "browser-host", "version" => "1"},
        %{"id" => "semantic-tree", "version" => "1"},
        %{"id" => "unused", "version" => "1"}
      ])

    features =
      Keyword.get(options, :features, [
        %{"id" => "atomvm-bundle", "state" => "supported", "reason" => "AVM loading"},
        %{"id" => "browser-dom", "state" => "supported", "reason" => "DOM bridge"},
        %{"id" => "timers", "state" => "supported", "reason" => "runtime timer"}
      ])

    maybe_reverse(
      %{
        "schema_version" => "1.0.0",
        "profile_id" => "atomvm-wasm.browser/1",
        "runtime" => runtime,
        "protocols" => protocols,
        "features" => features
      },
      options
    )
  end

  defp raw_requirements(options) do
    features = Keyword.get(options, :features, ["atomvm-bundle", "browser-dom"])

    maybe_reverse(
      %{
        "schema_version" => "1.0.0",
        "requirement_id" => "counter/1",
        "runtime" => %{"id" => "atomvm-wasm", "version" => "0.6.6-dev", "abi" => "atomvm.avm/1"},
        "protocols" => [
          %{"id" => "browser-host", "version" => "1"},
          %{"id" => "semantic-tree", "version" => "1"}
        ],
        "features" => features
      },
      options
    )
  end

  defp maybe_reverse(value, options) do
    if Keyword.get(options, :reversed, false) do
      value
      |> Map.put("protocols", Enum.reverse(value["protocols"]))
      |> Map.put("features", Enum.reverse(value["features"]))
    else
      value
    end
  end
end
