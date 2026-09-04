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
             "mailbox_messages" => 0,
             "pending_messages" => 0,
             "processes" => 0,
             "timers" => 0
           }

    assert {:error, %{"code" => "fixture-command-unknown"}} =
             LocalBehavior.command(11, %{"command" => "parent.increment"})
  end

  test "parent restart preserves sibling form and async ownership" do
    LocalBehavior.initialize(12)
    assert {:ok, _, _} = LocalBehavior.command(12, %{"command" => "mount"})
    assert {:ok, _, _} = LocalBehavior.command(12, %{"command" => "field.set", "value" => "Ada"})

    assert {:ok, _, _} =
             LocalBehavior.command(12, %{
               "command" => "timer.start",
               "delay_ms" => 100,
               "ticks" => 1
             })

    assert {:ok, _, _} = LocalBehavior.command(12, %{"command" => "parent.crash"})
    snapshot = LocalBehavior.snapshot(12)
    assert snapshot["parent_restarts"] == 1
    assert snapshot["field"]["value"] == "Ada"
    assert snapshot["resources"]["timers"] == 1
    assert {:ok, _, _} = LocalBehavior.command(12, %{"command" => "timer.cancel"})
  end

  test "form events keep only normalized values and deterministic validation state" do
    LocalBehavior.initialize(13)
    assert {:ok, mount, _} = LocalBehavior.command(13, %{"command" => "mount"})
    assert Enum.any?(mount["operations"], &(&1["id"] == "bx-field"))

    assert {:ok, composing, _} =
             LocalBehavior.event(
               13,
               field_event(13, "input", %{
                 "value" => "A",
                 "is_composing" => true,
                 "input_type" => "insertText"
               })
             )

    assert Enum.map(composing["operations"], & &1["op"]) == ["node.property"]
    assert LocalBehavior.snapshot(13)["field"]["composing"]

    assert {:ok, changed, _} =
             LocalBehavior.event(
               13,
               field_event(13, "change", %{
                 "value" => "Ada",
                 "is_composing" => false,
                 "input_type" => "unknown"
               })
             )

    assert Enum.map(changed["operations"], & &1["op"]) == [
             "node.property",
             "node.property",
             "node.text"
           ]

    assert LocalBehavior.snapshot(13)["field"] |> Map.take(["value", "valid", "error"]) == %{
             "value" => "Ada",
             "valid" => true,
             "error" => ""
           }

    assert {:ok, _, _} =
             LocalBehavior.event(13, field_event(13, "focus", %{"related_target" => "none"}))

    assert LocalBehavior.snapshot(13)["field"]["focused"]

    assert {:ok, _, _} =
             LocalBehavior.event(13, field_event(13, "blur", %{"related_target" => "present"}))

    snapshot = LocalBehavior.snapshot(13)["field"]
    assert snapshot["touched"]
    refute snapshot["focused"]
  end

  test "form rejects immutable, malformed, oversized, and stale transitions" do
    LocalBehavior.initialize(15)
    assert {:ok, _, _} = LocalBehavior.command(15, %{"command" => "mount"})

    assert {:ok, _, _} =
             LocalBehavior.command(15, %{"command" => "field.set", "value" => "Grace"})

    revision = LocalBehavior.snapshot(15)["field"]["validation_revision"]

    assert {:ok, stale, %{"result" => %{"accepted" => false}}} =
             LocalBehavior.command(15, %{
               "command" => "field.validation-result",
               "revision" => revision - 1,
               "value" => "Grace"
             })

    assert stale["operations"] == []
    assert LocalBehavior.snapshot(15)["stale_drops"] == 1

    assert {:ok, _, _} =
             LocalBehavior.command(15, %{"command" => "field.disabled", "value" => true})

    assert {:error, %{"code" => "fixture-field-disabled"}} =
             LocalBehavior.event(
               15,
               field_event(15, "input", %{
                 "value" => "blocked",
                 "is_composing" => false,
                 "input_type" => "insertText"
               })
             )

    assert {:ok, _, _} =
             LocalBehavior.command(15, %{"command" => "field.disabled", "value" => false})

    assert {:ok, _, _} =
             LocalBehavior.command(15, %{"command" => "field.read-only", "value" => true})

    assert {:error, %{"code" => "fixture-field-read-only"}} =
             LocalBehavior.event(
               15,
               field_event(15, "change", %{
                 "value" => "blocked",
                 "is_composing" => false,
                 "input_type" => "unknown"
               })
             )

    assert {:error, %{"code" => "fixture-field-event-invalid"}} =
             LocalBehavior.event(15, field_event(15, "input", %{"value" => "missing flags"}))

    assert {:error, %{"code" => "fixture-field-event-invalid"}} =
             LocalBehavior.event(
               15,
               field_event(15, "input", %{
                 "value" => String.duplicate("x", 2_049),
                 "is_composing" => false
               })
             )

    assert {:ok, _, _} = LocalBehavior.command(15, %{"command" => "field.reset"})
    assert LocalBehavior.snapshot(15)["field"]["value"] == ""
  end

  test "form disposal rejects late input and a new generation remounts cleanly" do
    LocalBehavior.initialize(17)
    assert {:ok, _, _} = LocalBehavior.command(17, %{"command" => "mount"})
    assert {:ok, _, _} = LocalBehavior.command(17, %{"command" => "dispose"})

    assert {:error, %{"code" => "fixture-field-event-invalid"}} =
             LocalBehavior.event(
               17,
               field_event(17, "input", %{
                 "value" => "late",
                 "is_composing" => false,
                 "input_type" => "insertText"
               })
             )

    assert {:ok, _, _} = LocalBehavior.command(18, %{"command" => "mount"})
    snapshot = LocalBehavior.snapshot(18)
    assert snapshot["generation"] == 18
    assert snapshot["field"]["value"] == ""
    refute snapshot["disposed"]
  end

  test "bounded repeated timers update visible state and converge" do
    LocalBehavior.initialize(19)
    assert {:ok, _, _} = LocalBehavior.command(19, %{"command" => "mount"})

    assert {:ok, _, %{"result" => %{"timer_epoch" => token}}} =
             LocalBehavior.command(19, %{
               "command" => "timer.start",
               "delay_ms" => 5,
               "ticks" => 2
             })

    assert LocalBehavior.snapshot(19)["resources"]["timers"] == 1
    assert_receive {:bh01_fixture_timer, 19, ^token} = first, 100
    assert {:ok, first_effect, _} = LocalBehavior.async(19, first)
    assert [%{"text" => "Timer tick 1/2"}] = first_effect["operations"]
    assert LocalBehavior.snapshot(19)["resources"]["timers"] == 1

    assert_receive {:bh01_fixture_timer, 19, ^token} = second, 100
    assert {:ok, second_effect, _} = LocalBehavior.async(19, second)
    assert [%{"text" => "Timer tick 2/2"}] = second_effect["operations"]

    snapshot = LocalBehavior.snapshot(19)
    assert snapshot["async"]["timer_ticks"] == 2
    assert snapshot["resources"]["timers"] == 0
  end

  test "timer cancellation and crash invalidate late ticks before retry" do
    LocalBehavior.initialize(21)
    assert {:ok, _, _} = LocalBehavior.command(21, %{"command" => "mount"})

    assert {:ok, _, %{"result" => %{"timer_epoch" => old_token}}} =
             LocalBehavior.command(21, %{
               "command" => "timer.start",
               "delay_ms" => 100,
               "ticks" => 1
             })

    assert {:ok, _, _} = LocalBehavior.command(21, %{"command" => "timer.cancel"})

    assert {:ok, stale, %{"result" => %{"accepted" => false}}} =
             LocalBehavior.async(21, {:bh01_fixture_timer, 21, old_token})

    assert stale["operations"] == []

    assert {:ok, _, _} =
             LocalBehavior.command(21, %{
               "command" => "timer.start",
               "delay_ms" => 100,
               "ticks" => 1
             })

    assert {:ok, _, _} = LocalBehavior.command(21, %{"command" => "timer.crash"})
    assert LocalBehavior.snapshot(21)["failures"] == 1
    assert LocalBehavior.snapshot(21)["resources"]["timers"] == 0

    assert {:ok, _, _} =
             LocalBehavior.command(21, %{
               "command" => "timer.start",
               "delay_ms" => 100,
               "ticks" => 1
             })

    assert LocalBehavior.snapshot(21)["resources"]["timers"] == 1
    assert {:ok, _, _} = LocalBehavior.command(21, %{"command" => "timer.cancel"})
  end

  test "messages preserve order, reject duplicates and stale generations, and drain" do
    LocalBehavior.initialize(23)
    assert {:ok, _, _} = LocalBehavior.command(23, %{"command" => "mount"})

    assert {:ok, _, _} =
             LocalBehavior.command(23, %{
               "command" => "message.duplicate",
               "message_id" => "message-one",
               "value" => "hello"
             })

    assert_receive {:bh01_fixture_message, 23, "message-one", "hello"} = first, 100
    assert_receive {:bh01_fixture_message, 23, "message-one", "hello"} = duplicate, 100
    assert {:ok, accepted, _} = LocalBehavior.async(23, first)
    assert [%{"text" => "Message message-one: hello"}] = accepted["operations"]

    assert {:ok, dropped, %{"result" => %{"accepted" => false}}} =
             LocalBehavior.async(23, duplicate)

    assert dropped["operations"] == []

    assert {:ok, _, _} =
             LocalBehavior.command(23, %{
               "command" => "message.late",
               "message_id" => "message-late",
               "value" => "late",
               "generation" => 22
             })

    assert_receive {:bh01_fixture_message, 22, "message-late", "late"} = late, 100
    assert {:ok, _, %{"result" => %{"accepted" => false}}} = LocalBehavior.async(23, late)

    snapshot = LocalBehavior.snapshot(23)
    assert snapshot["async"]["messages"] == 1
    assert snapshot["async"]["duplicate_drops"] == 1
    assert snapshot["resources"]["pending_messages"] == 0
    assert snapshot["stale_drops"] == 2
  end

  test "host-dispatched stale messages cannot replace the active generation" do
    LocalBehavior.initialize(27)
    assert {:ok, _, _} = LocalBehavior.command(28, %{"command" => "mount"})

    assert {:ok, _, %{"result" => %{"accepted" => false}}} =
             LocalBehavior.async({:bh01_fixture_message, 999, "stale", "late"})

    snapshot = LocalBehavior.snapshot(28)
    assert snapshot["generation"] == 28
    assert snapshot["stale_drops"] == 1
  end

  test "disposal cancels timers and rejects pending async work" do
    LocalBehavior.initialize(25)
    assert {:ok, _, _} = LocalBehavior.command(25, %{"command" => "mount"})

    assert {:ok, _, _} =
             LocalBehavior.command(25, %{
               "command" => "timer.start",
               "delay_ms" => 100,
               "ticks" => 2
             })

    assert {:ok, _, _} =
             LocalBehavior.command(25, %{
               "command" => "message.send",
               "message_id" => "pending",
               "value" => "late"
             })

    assert_receive {:bh01_fixture_message, 25, "pending", "late"} = pending, 100
    assert {:ok, _, _} = LocalBehavior.command(25, %{"command" => "dispose"})

    assert {:ok, late, %{"result" => %{"accepted" => false}}} =
             LocalBehavior.async(25, pending)

    assert late["operations"] == []

    assert LocalBehavior.snapshot(25)["resources"] == %{
             "mailbox_messages" => 0,
             "pending_messages" => 0,
             "processes" => 0,
             "timers" => 0
           }
  end

  defp field_event(generation, event, payload) do
    %{
      "protocol" => "blazex.bh01.fixture-event/0.1",
      "record_type" => "event",
      "scenario_id" => "BX-BH01-SCENARIO-LOCAL-BROWSER",
      "generation" => generation,
      "sequence" => 1,
      "node_id" => "bx-field",
      "event" => event,
      "payload" => payload
    }
  end
end
