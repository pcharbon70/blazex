defmodule BlazeXBrowserPhoenix.CounterChannelTest do
  use ExUnit.Case, async: false
  import Phoenix.ChannelTest

  alias BlazeX.Phoenix.{CommandAdmission, CommandExecution, SessionRegistry}

  @endpoint BlazeXBrowserPhoenix.Endpoint

  setup do
    SessionRegistry.reset()
    CommandAdmission.reset()
    CommandExecution.reset()
    :ok
  end

  test "two authenticated sockets receive one redacted server update" do
    first = session("operator")
    second = session("operator")
    {:ok, first_socket} = connect_session(first)
    {:ok, second_socket} = connect_session(second)

    assert {:ok, %{"mode" => "replay", "cursor" => 0}, _first_channel} =
             subscribe_and_join(first_socket, "bh07:counter", join_payload(0))

    assert {:ok, %{"mode" => "replay", "cursor" => 0}, _second_channel} =
             subscribe_and_join(second_socket, "bh07:counter", join_payload(0))

    assert {:ok, _result} = execute(first, 0, "cross-session")

    assert_push("counter", event)
    assert_push("counter", ^event)
    assert event["protocol"] == "blazex.bh07.counter-update/1"
    assert event["sequence"] == 1
    assert event["resource"] == %{"id" => "counter", "value" => 1, "revision" => 1}
    refute inspect(event) =~ first["session_id"]
    refute inspect(event) =~ first["csrf_token"]
  end

  test "reconnect replays events after the supplied cursor without duplicates" do
    identity = session("operator")
    {:ok, socket} = connect_session(identity)

    {:ok, %{"cursor" => 0}, channel} =
      subscribe_and_join(socket, "bh07:counter", join_payload(0))

    assert {:ok, _result} = execute(identity, 0, "event-one")
    assert_push("counter", %{"sequence" => 1})
    Process.unlink(channel.channel_pid)
    close(channel)
    await_subscribers(0)

    assert {:ok, _result} = execute(identity, 1, "event-two")
    refute_push("counter", _event)

    {:ok, replacement} = connect_session(identity)

    assert {:ok, %{"mode" => "replay", "cursor" => 2, "events" => [event]}, _channel} =
             subscribe_and_join(replacement, "bh07:counter", join_payload(1))

    assert event["sequence"] == 2
    assert event["resource"]["revision"] == 2
  end

  test "forged, expired, malformed, and future-cursor connections fail closed" do
    identity = session("operator")

    assert :error =
             connect(BlazeXBrowserPhoenix.Socket, connect_payload("incorrect"),
               connect_info: connect_info(identity)
             )

    assert :error =
             connect(
               BlazeXBrowserPhoenix.Socket,
               Map.put(connect_payload(identity["csrf_token"]), "authority", "operator"),
               connect_info: connect_info(identity)
             )

    expired = session("operator", now_ms: 0, ttl_ms: 1)

    assert :error =
             connect(BlazeXBrowserPhoenix.Socket, connect_payload(expired["csrf_token"]),
               connect_info: connect_info(expired)
             )

    {:ok, socket} = connect_session(identity)

    assert {:error, %{"error" => %{"code" => "push-join-invalid"}}} =
             subscribe_and_join(socket, "bh07:counter", %{"after_sequence" => 0})

    assert {:error, %{"error" => %{"code" => "push-cursor-invalid"}}} =
             subscribe_and_join(socket, "bh07:counter", join_payload(1))

    assert CommandExecution.snapshot()["subscribers"] == 0
  end

  test "every client channel event is denied without mutation" do
    identity = session("operator")
    {:ok, socket} = connect_session(identity)
    {:ok, _sync, channel} = subscribe_and_join(socket, "bh07:counter", join_payload(0))

    reference = push(channel, "counter.increment", %{"amount" => 10})

    assert_reply(reference, :error, %{
      "protocol" => "blazex.bh07.push-error/1",
      "error" => %{"code" => "push-client-event-denied"}
    })

    assert CommandExecution.snapshot()["resource"]["value"] == 0
    assert CommandAdmission.snapshot()["admissions"] == 0
  end

  test "channel teardown and session revocation release subscriptions" do
    identity = session("operator")
    {:ok, socket} = connect_session(identity)
    {:ok, _sync, channel} = subscribe_and_join(socket, "bh07:counter", join_payload(0))
    assert CommandExecution.snapshot()["subscribers"] == 1

    Process.unlink(channel.channel_pid)
    close(channel)
    await_subscribers(0)

    {:ok, replacement} = connect_session(identity)
    {:ok, _sync, _channel} = subscribe_and_join(replacement, "bh07:counter", join_payload(0))
    assert CommandExecution.snapshot()["subscribers"] == 1

    assert :ok = CommandExecution.revoke_session(identity["session_id"])
    assert CommandExecution.snapshot()["subscribers"] == 0
  end

  defp session(subject, options \\ []) do
    assert {:ok, value} =
             SessionRegistry.issue(subject, String.capitalize(subject), options)

    value
  end

  defp connect_session(identity) do
    connect(BlazeXBrowserPhoenix.Socket, connect_payload(identity["csrf_token"]),
      connect_info: connect_info(identity)
    )
  end

  defp connect_info(identity) do
    %{
      session: %{
        bh07_session_id: identity["session_id"],
        bh07_csrf_token: identity["csrf_token"]
      }
    }
  end

  defp connect_payload(csrf) do
    %{"protocol" => "blazex.bh07.push-connect/1", "csrf_token" => csrf, "vsn" => "1.0.0"}
  end

  defp join_payload(cursor) do
    %{"protocol" => "blazex.bh07.push-join/1", "after_sequence" => cursor}
  end

  defp execute(identity, expected_revision, key) do
    envelope = %{
      "protocol" => "blazex.bh07.command-intent/1",
      "command" => "counter.increment",
      "schema" => "counter.increment",
      "correlation_id" => key,
      "idempotency_key" => key,
      "expected_revision" => expected_revision,
      "payload" => %{"amount" => 1}
    }

    CommandExecution.execute(identity["session_id"], identity["csrf_token"], envelope)
  end

  defp await_subscribers(expected, attempts \\ 20)

  defp await_subscribers(expected, 0),
    do: assert(CommandExecution.snapshot()["subscribers"] == expected)

  defp await_subscribers(expected, attempts) do
    if CommandExecution.snapshot()["subscribers"] == expected do
      :ok
    else
      Process.sleep(5)
      await_subscribers(expected, attempts - 1)
    end
  end
end
