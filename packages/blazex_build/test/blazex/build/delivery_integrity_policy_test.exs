defmodule BlazeX.Build.DeliveryIntegrityPolicyTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.DeliveryIntegrityPolicy

  test "accepts a bounded closed policy without creating atoms" do
    before = :erlang.system_info(:atom_count)
    policy = DeliveryIntegrityPolicy.new!(policy())
    assert policy.id == "test.delivery/1"
    assert policy.algorithm == "sha384"
    assert :erlang.system_info(:atom_count) == before
  end

  test "rejects unsupported algorithms, cache values, extra keys, and limits" do
    assert_raise ArgumentError, fn ->
      DeliveryIntegrityPolicy.new!(put_in(policy()["integrity_algorithm"], "sha512"))
    end

    assert_raise ArgumentError, fn ->
      DeliveryIntegrityPolicy.new!(
        put_in(policy()["roles"]["document"]["cache_control"], "max-age=2")
      )
    end

    assert_raise ArgumentError, fn ->
      DeliveryIntegrityPolicy.new!(Map.put(policy(), "surprise", true))
    end

    assert_raise ArgumentError, fn ->
      DeliveryIntegrityPolicy.new!(put_in(policy()["limits"]["max_artifacts"], 0))
    end
  end

  defp policy do
    %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.delivery/1",
      "integrity_algorithm" => "sha384",
      "roles" => %{
        "document" => %{"cache_control" => "no-store", "cardinality" => "exactly-one"}
      },
      "limits" => %{"max_artifacts" => 4, "max_total_bytes" => 1024, "max_role_length" => 32}
    }
  end
end
