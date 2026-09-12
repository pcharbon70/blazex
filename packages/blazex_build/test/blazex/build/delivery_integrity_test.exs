defmodule BlazeX.Build.DeliveryIntegrityTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{DeliveryIntegrity, DeliveryIntegrityPolicy}

  setup do
    root =
      Path.join(System.tmp_dir!(), "delivery-integrity-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    File.write!(Path.join(root, "index.html"), "hello")
    on_exit(fn -> File.rm_rf!(root) end)

    artifact = %{
      "path" => "index.html",
      "role" => "document",
      "bytes" => 5,
      "sha256" => :crypto.hash(:sha256, "hello") |> Base.encode16(case: :lower)
    }

    policy =
      DeliveryIntegrityPolicy.new!(%{
        "schema_version" => "1.0.0",
        "policy_id" => "test.delivery/1",
        "integrity_algorithm" => "sha384",
        "roles" => %{
          "document" => %{"cache_control" => "no-store", "cardinality" => "exactly-one"}
        },
        "limits" => %{
          "max_artifacts" => 2,
          "max_total_bytes" => 100,
          "max_role_length" => 32
        }
      })

    %{root: root, manifest: %{"artifacts" => [artifact]}, policy: policy}
  end

  test "adds deterministic SRI, cache metadata, and a policy binding", context do
    one = DeliveryIntegrity.apply!(context.manifest, context.root, context.policy)
    two = DeliveryIntegrity.apply!(context.manifest, context.root, context.policy)
    assert one == two
    assert :ok = DeliveryIntegrity.verify!(one, context.root, context.policy)

    [artifact] = one["artifacts"]

    assert artifact["integrity"] ==
             "sha384-" <> (:crypto.hash(:sha384, "hello") |> Base.encode64())

    assert artifact["cache_control"] == "no-store"
    assert one["delivery_integrity"]["policy_id"] == context.policy.id
    assert one["delivery_integrity"]["manifest_cache_control"] == "no-store"
  end

  test "rejects content, metadata, role, path, and limit drift", context do
    decorated = DeliveryIntegrity.apply!(context.manifest, context.root, context.policy)
    File.write!(Path.join(context.root, "index.html"), "other")

    assert_raise ArgumentError, ~r/identity drift/, fn ->
      DeliveryIntegrity.verify!(decorated, context.root, context.policy)
    end

    File.write!(Path.join(context.root, "index.html"), "hello")

    altered = %{
      decorated
      | "artifacts" => [Map.put(hd(decorated["artifacts"]), "cache_control", "wrong")]
    }

    assert_raise ArgumentError, ~r/metadata drift/, fn ->
      DeliveryIntegrity.verify!(altered, context.root, context.policy)
    end

    assert_raise ArgumentError, ~r/unknown or unused/, fn ->
      DeliveryIntegrity.apply!(
        %{
          context.manifest
          | "artifacts" => [Map.put(hd(context.manifest["artifacts"]), "role", "other")]
        },
        context.root,
        context.policy
      )
    end

    escaping = %{
      context.manifest
      | "artifacts" => [Map.put(hd(context.manifest["artifacts"]), "path", "../index.html")]
    }

    assert_raise ArgumentError, ~r/path escapes/, fn ->
      DeliveryIntegrity.apply!(escaping, context.root, context.policy)
    end

    oversized = %{context.policy | limits: Map.put(context.policy.limits, "max_total_bytes", 4)}

    assert_raise ArgumentError, ~r/bytes exceed/, fn ->
      DeliveryIntegrity.apply!(context.manifest, context.root, oversized)
    end
  end
end
