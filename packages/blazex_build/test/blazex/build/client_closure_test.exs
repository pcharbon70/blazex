defmodule BlazeX.Build.ClientClosureTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{ClientClosure, ClientSafetyError, ClientSafetyPolicy}

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
end
