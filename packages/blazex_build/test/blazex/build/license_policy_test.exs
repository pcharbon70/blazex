defmodule BlazeX.Build.LicensePolicyTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.LicensePolicy

  test "normalizes unordered records and components deterministically" do
    left = policy()

    right =
      policy()
      |> Map.update!("license_records", &Enum.reverse/1)
      |> Map.update!("components", &Enum.reverse/1)

    assert LicensePolicy.new!(left).sha256 == LicensePolicy.new!(right).sha256
  end

  test "rejects unknown fields, duplicate ids, and unknown record references" do
    assert_raise ArgumentError, fn -> LicensePolicy.new!(Map.put(policy(), "extra", true)) end

    duplicate = Map.update!(policy(), "components", &(&1 ++ &1))
    assert_raise ArgumentError, fn -> LicensePolicy.new!(duplicate) end

    unknown = put_in(policy(), ["components", Access.at(0), "license_record_ids"], ["MISSING"])
    assert_raise ArgumentError, fn -> LicensePolicy.new!(unknown) end
  end

  test "private records cannot disguise an external notice declaration" do
    invalid =
      policy()
      |> put_in(["license_records", Access.at(0), "notice_path"], "NOTICE")
      |> put_in(["license_records", Access.at(0), "notice_sha256"], String.duplicate("0", 64))

    assert_raise ArgumentError, fn -> LicensePolicy.new!(invalid) end
  end

  def policy do
    %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.license/1",
      "limits" => %{"max_inputs" => 10, "max_input_bytes" => 100, "max_total_bytes" => 200},
      "license_records" => [
        %{
          "id" => "PRIVATE",
          "license" => "NOASSERTION",
          "disposition" => "private-development-only",
          "notice_path" => nil,
          "notice_sha256" => nil
        },
        %{
          "id" => "THIRD-PARTY",
          "license" => "MIT",
          "disposition" => "known-retention-required",
          "notice_path" => "NOTICE",
          "notice_sha256" => String.duplicate("0", 64)
        }
      ],
      "components" => [
        %{
          "id" => "app",
          "name" => "App",
          "source" => "workspace",
          "version" => "dev",
          "scope" => "shipped",
          "license_record_ids" => ["PRIVATE"]
        },
        %{
          "id" => "tool",
          "name" => "Tool",
          "source" => "tool",
          "version" => "1",
          "scope" => "build-only",
          "license_record_ids" => ["THIRD-PARTY"]
        }
      ]
    }
  end
end
