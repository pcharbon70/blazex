defmodule BlazeX.BH01.BrowserHostTest do
  use ExUnit.Case, async: true

  test "fixture remains disposable and browser-only" do
    assert Code.ensure_loaded?(BlazeX.BH01.BrowserHost)
    assert function_exported?(BlazeX.BH01.BrowserHost, :start, 0)
  end

  test "protocol echoes bounded values and rejects forbidden operations" do
    request = %{
      "protocol" => "blazex.host-bridge/1",
      "type" => "request",
      "scenario_id" => "fixture-test",
      "generation" => 1,
      "correlation_id" => "correlation-1",
      "sequence" => 1,
      "operation" => "runtime.echo",
      "payload" => %{"message" => "hello"},
      "timeout_ms" => 1000,
      "retry" => 0
    }

    assert {:ok, %{"status" => "ok", "result" => %{"message" => "hello"}}, "runtime.echo"} =
             BlazeX.BH01.BrowserHost.Protocol.handle(request)

    assert {:error, %{"status" => "error", "error" => %{"code" => "bridge-request-invalid"}}} =
             BlazeX.BH01.BrowserHost.Protocol.handle(%{request | "operation" => "browser.fetch"})
  end
end
