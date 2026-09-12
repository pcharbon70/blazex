defmodule BlazeX.Build.LicenseInventoryTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.{LicenseInventory, LicensePolicy}
  alias BlazeX.Build.LicensePolicyTest

  test "accounts for shipped bytes, notices, licenses, and build-only lineage", %{test: test} do
    root = temporary(test)
    File.write!(Path.join(root, "NOTICE"), "notice")
    policy = policy(root)

    report =
      LicenseInventory.analyze!(
        [input("bundle/app.beam", "abc", "app")],
        policy,
        root
      )

    assert report["complete"]

    assert report["summary"] == %{
             "inputs" => 1,
             "input_bytes" => 3,
             "shipped_components" => 1,
             "build_only_components" => 1,
             "license_records" => 2,
             "verified_notices" => 1
           }

    assert [%{"component_id" => "app", "label" => "bundle/app.beam"}] = report["inputs"]
    assert [%{"id" => "tool", "scope" => "build-only"}] = report["build_lineage"]
  end

  test "is deterministic and rejects duplicate, unknown, and build-only ownership", %{test: test} do
    root = temporary(test)
    File.write!(Path.join(root, "NOTICE"), "notice")
    policy = policy(root)
    one = input("one", "1", "app")
    two = input("two", "22", "app")

    assert LicenseInventory.analyze!([one, two], policy, root) ==
             LicenseInventory.analyze!([two, one], policy, root)

    assert_raise ArgumentError, fn -> LicenseInventory.analyze!([one, one], policy, root) end

    assert_raise ArgumentError, fn ->
      LicenseInventory.analyze!([%{one | "component_id" => "missing"}], policy, root)
    end

    assert_raise ArgumentError, fn ->
      LicenseInventory.analyze!([%{one | "component_id" => "tool"}], policy, root)
    end
  end

  test "rejects notice drift and explicit scaling overflow", %{test: test} do
    root = temporary(test)
    File.write!(Path.join(root, "NOTICE"), "notice")
    policy = policy(root)
    File.write!(Path.join(root, "NOTICE"), "changed")

    assert_raise ArgumentError, fn ->
      LicenseInventory.analyze!([input("one", "1", "app")], policy, root)
    end

    File.write!(Path.join(root, "NOTICE"), "notice")

    assert_raise ArgumentError, fn ->
      LicenseInventory.analyze!([input("large", String.duplicate("x", 101), "app")], policy, root)
    end
  end

  defp policy(root) do
    sha =
      :crypto.hash(:sha256, File.read!(Path.join(root, "NOTICE"))) |> Base.encode16(case: :lower)

    LicensePolicyTest.policy()
    |> put_in(["license_records", Access.at(1), "notice_sha256"], sha)
    |> LicensePolicy.new!()
  end

  defp input(label, bytes, component),
    do: %{"label" => label, "bytes" => bytes, "component_id" => component}

  defp temporary(test) do
    path =
      Path.join(System.tmp_dir!(), "blazex-license-#{test}-#{System.unique_integer([:positive])}")

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf!(path) end)
    path
  end
end
