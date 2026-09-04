defmodule BlazeX.BH01.BrowserHostTest do
  use ExUnit.Case, async: true

  alias BlazeX.BH01.LocalBehavior

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

  test "nested fixture preserves keyed identity through independent updates and reorder" do
    LocalBehavior.initialize(7)
    assert {:ok, mount, _} = LocalBehavior.command(7, %{"command" => "mount"})
    assert mount["generation"] == 7
    assert Enum.any?(mount["operations"], &(&1["id"] == "bx-child-alpha"))

    assert {:ok, _, _} =
             LocalBehavior.command(7, %{"command" => "child.increment", "key" => "alpha"})

    assert {:ok, _, _} =
             LocalBehavior.command(7, %{"command" => "child.insert", "key" => "gamma"})

    assert {:ok, reorder, _} =
             LocalBehavior.command(7, %{
               "command" => "child.reorder",
               "keys" => ["gamma", "beta", "alpha"]
             })

    assert Enum.map(reorder["operations"], & &1["id"]) == [
             "bx-child-gamma",
             "bx-child-beta",
             "bx-child-alpha"
           ]

    snapshot = LocalBehavior.snapshot(7)
    assert Enum.map(snapshot["children"], & &1["key"]) == ["gamma", "beta", "alpha"]
    assert Enum.find(snapshot["children"], &(&1["key"] == "alpha"))["count"] == 1
    assert Enum.find(snapshot["children"], &(&1["key"] == "beta"))["count"] == 0
  end

  test "nested fixture rejects duplicate and missing identity and drops late output" do
    LocalBehavior.initialize(9)
    assert {:ok, _, _} = LocalBehavior.command(9, %{"command" => "mount"})

    assert {:error, %{"code" => "fixture-child-duplicate"}} =
             LocalBehavior.command(9, %{"command" => "child.insert", "key" => "alpha"})

    assert {:error, %{"code" => "fixture-child-missing"}} =
             LocalBehavior.command(9, %{"command" => "child.increment", "key" => "missing"})

    assert {:ok, effect, %{"result" => %{"accepted" => false}}} =
             LocalBehavior.command(9, %{
               "command" => "child.late-output",
               "key" => "alpha",
               "generation" => 8
             })

    assert effect["operations"] == []
    assert LocalBehavior.snapshot(9)["stale_drops"] == 1
  end

  test "nested crash, replace, remove, and disposal remain internal and bounded" do
    LocalBehavior.initialize(11)
    assert {:ok, _, _} = LocalBehavior.command(11, %{"command" => "mount"})

    assert {:ok, _, %{"result" => %{"restarted_instance" => 2}}} =
             LocalBehavior.command(11, %{"command" => "child.crash", "key" => "alpha"})

    assert {:ok, _, _} =
             LocalBehavior.command(11, %{
               "command" => "child.replace",
               "old_key" => "beta",
               "new_key" => "delta"
             })

    assert Enum.map(LocalBehavior.snapshot(11)["children"], & &1["key"]) == ["alpha", "delta"]

    assert {:ok, _, _} =
             LocalBehavior.command(11, %{"command" => "child.remove", "key" => "alpha"})

    assert {:ok, dispose, _} = LocalBehavior.command(11, %{"command" => "dispose"})
    assert [%{"op" => "root.dispose"}] = dispose["operations"]

    assert LocalBehavior.snapshot(11)["resources"] == %{
             "pending_messages" => 0,
             "processes" => 0,
             "timers" => 0
           }

    assert {:error, %{"code" => "fixture-command-unknown"}} =
             LocalBehavior.command(11, %{"command" => "parent.increment"})
  end
end
