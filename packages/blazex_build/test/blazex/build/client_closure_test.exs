defmodule BlazeX.Build.ClientClosureTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{
    BundlePolicy,
    ClientClosure,
    ClientSafetyError,
    ClientSafetyPolicy,
    CompatibilityError,
    CompatibilityProfile,
    CompatibilityRequirements,
    LicensePolicy,
    SecretAuditError,
    SecretPolicy
  }

  @reachability %{"modules" => [%{"module" => "Elixir.App.Root"}], "external_references" => []}
  @inventory [%{"module" => "Elixir.App.Root", "application" => "app", "imports" => []}]

  test "invokes assembly only after safety passes" do
    caller = self()

    {report, :assembled} =
      ClientClosure.authorize!(@reachability, @inventory, policy("client-safe"), fn safety ->
        send(caller, {:assembled, safety["policy_sha256"]})
        :assembled
      end)

    assert_received {:assembled, hash}
    assert hash == report["policy_sha256"]
  end

  test "does not invoke assembly after safety rejection" do
    caller = self()

    assert_raise ClientSafetyError, fn ->
      ClientClosure.authorize!(@reachability, @inventory, policy("server-only"), fn _ ->
        send(caller, :assembled)
      end)
    end

    refute_received :assembled
  end

  test "invokes assembly only after safety and compatibility pass" do
    caller = self()

    {safety, compatibility, :assembled} =
      ClientClosure.authorize!(
        @reachability,
        @inventory,
        policy("client-safe"),
        profile(),
        requirements(),
        fn authorization ->
          send(caller, {:assembled, authorization})
          :assembled
        end
      )

    assert_received {:assembled, authorization}
    assert authorization["client_safety"] == safety
    assert authorization["compatibility"] == compatibility
  end

  test "does not invoke assembly after compatibility rejection" do
    caller = self()

    assert_raise CompatibilityError, fn ->
      ClientClosure.authorize!(
        @reachability,
        @inventory,
        policy("client-safe"),
        profile(),
        requirements("other-version"),
        fn _ -> send(caller, :assembled) end
      )
    end

    refute_received :assembled
  end

  test "does not invoke assembly after a redacted secret finding" do
    caller = self()

    assert_raise SecretAuditError, fn ->
      ClientClosure.authorize!(
        @reachability,
        @inventory,
        policy("client-safe"),
        profile(),
        requirements(),
        secret_policy(),
        [%{"label" => "candidate.beam", "bytes" => "ghp_example"}],
        %{},
        fn _ -> send(caller, :assembled) end
      )
    end

    refute_received :assembled
  end

  test "does not invoke assembly when license ownership is unknown" do
    caller = self()
    bytes = [%{"label" => "candidate.beam", "bytes" => "clean"}]
    licenses = [%{"label" => "candidate.beam", "bytes" => "clean", "component_id" => "missing"}]

    assert_raise ArgumentError, ~r/unknown or not shipped/, fn ->
      ClientClosure.authorize!(
        @reachability,
        @inventory,
        policy("client-safe"),
        profile(),
        requirements(),
        secret_policy(),
        bytes,
        %{},
        license_policy(),
        licenses,
        System.tmp_dir!(),
        fn _ -> send(caller, :assembled) end
      )
    end

    refute_received :assembled
  end

  test "does not invoke assembly when feature membership is incomplete" do
    caller = self()
    secret_inputs = [%{"label" => "bundle/Elixir.App.Boot.beam", "bytes" => "boot"}]

    license_inputs = [
      %{"label" => "bundle/Elixir.App.Boot.beam", "bytes" => "boot", "component_id" => "app"}
    ]

    bundle_inputs = [
      %{
        "label" => "bundle/Elixir.App.Boot.beam",
        "module" => "Elixir.App.Boot",
        "bundle_id" => "base",
        "bytes" => "boot"
      }
    ]

    assert_raise ArgumentError, ~r/module set/, fn ->
      ClientClosure.authorize!(
        @reachability,
        @inventory,
        policy("client-safe"),
        profile(),
        requirements(),
        secret_policy(),
        secret_inputs,
        %{},
        license_policy(),
        license_inputs,
        System.tmp_dir!(),
        bundle_policy(),
        bundle_inputs,
        fn _ -> send(caller, :assembled) end
      )
    end

    refute_received :assembled
  end

  defp policy(classification) do
    ClientSafetyPolicy.new!(%{
      "schema_version" => "1.0.0",
      "policy_id" => "test.closure/1",
      "applications" => [
        %{"id" => "app", "classification" => classification, "reason" => "test rule"}
      ],
      "module_overrides" => [],
      "external_modules" => [],
      "forbidden_imports" => []
    })
  end

  defp profile do
    CompatibilityProfile.new!(%{
      "schema_version" => "1.0.0",
      "profile_id" => "test.profile/1",
      "runtime" => %{"id" => "runtime", "version" => "1", "abi" => "avm/1"},
      "protocols" => [],
      "features" => []
    })
  end

  defp requirements(version \\ "1") do
    CompatibilityRequirements.new!(%{
      "schema_version" => "1.0.0",
      "requirement_id" => "test.requirements/1",
      "runtime" => %{"id" => "runtime", "version" => version, "abi" => "avm/1"},
      "protocols" => [],
      "features" => []
    })
  end

  defp secret_policy do
    SecretPolicy.new!(%{
      "schema_version" => "1.0.0",
      "policy_id" => "test.secret/1",
      "key_fragments" => [],
      "literal_rules" => [%{"id" => "github", "literal" => "ghp_", "reason" => "token"}],
      "limits" => %{
        "max_inputs" => 10,
        "max_input_bytes" => 100,
        "max_total_bytes" => 100,
        "max_findings" => 10
      }
    })
  end

  defp license_policy do
    LicensePolicy.new!(%{
      "schema_version" => "1.0.0",
      "policy_id" => "test.license/1",
      "limits" => %{"max_inputs" => 10, "max_input_bytes" => 100, "max_total_bytes" => 100},
      "license_records" => [
        %{
          "id" => "PRIVATE",
          "license" => "NOASSERTION",
          "disposition" => "private-development-only",
          "notice_path" => nil,
          "notice_sha256" => nil
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
        }
      ]
    })
  end

  defp bundle_policy do
    BundlePolicy.new!(%{
      "schema_version" => "1.0.0",
      "policy_id" => "test.bundles/1",
      "base_bundle_id" => "base",
      "startup_modules" => ["Elixir.App.Boot"],
      "features" => [
        %{
          "id" => "counter",
          "entrypoint_ids" => ["counter"],
          "modules" => ["Elixir.App.Counter"]
        }
      ],
      "limits" => %{
        "max_bundles" => 4,
        "max_inputs" => 10,
        "max_input_bytes" => 100,
        "max_total_bytes" => 100
      }
    })
  end
end
