defmodule BlazeX.Phoenix.CommandExecutionTest do
  use ExUnit.Case, async: true

  alias BlazeX.Phoenix.{CommandAdmission, CommandExecution, SessionRegistry}

  setup do
    suffix = System.unique_integer([:positive])
    sessions = Module.concat(__MODULE__, "Sessions#{suffix}")
    admissions = Module.concat(__MODULE__, "Admissions#{suffix}")
    executions = Module.concat(__MODULE__, "Executions#{suffix}")

    start_supervised!({SessionRegistry, name: sessions})
    start_supervised!({CommandAdmission, admission_options(admissions)})
    start_supervised!({CommandExecution, name: executions})

    %{sessions: sessions, admissions: admissions, executions: executions}
  end

  test "executes the closed command once and replays the retained result", context do
    session = session(context, "operator")
    command = command("first", "first-key", 0, 3)

    assert {:ok, %{"result" => %{"value" => 3, "revision" => 1, "replayed" => false}}} =
             execute(context, session, command)

    assert {:ok, %{"result" => %{"value" => 3, "revision" => 1, "replayed" => true}}} =
             execute(context, session, command)

    snapshot = CommandExecution.snapshot(context.executions)
    assert snapshot["resource"] == %{"id" => "counter", "value" => 3, "revision" => 1}
    assert snapshot["executions"] == 1
    assert Enum.map(snapshot["audit"], & &1["outcome"]) == ["executed", "replayed"]
  end

  test "retains stale denial so it cannot become executable later", context do
    first = session(context, "operator")
    future = command("future", "future-key", 1, 2)

    assert {:error, %{"error" => %{"code" => "state-stale", "replayed" => false}}} =
             execute(context, first, future)

    second = session(context, "operator")
    assert {:ok, _result} = execute(context, second, command("advance", "advance-key", 0, 1))

    assert {:error, %{"error" => %{"code" => "state-stale", "replayed" => true}}} =
             execute(context, first, future)

    assert CommandExecution.snapshot(context.executions)["resource"]["value"] == 1
  end

  test "denies viewer, malformed, and changed-key requests without mutation", context do
    viewer = session(context, "viewer")

    assert {:error, %{"error" => %{"code" => "authorization-denied"}}} =
             execute(context, viewer, command("viewer", "viewer-key", 0, 1))

    operator = session(context, "operator")
    original = command("original", "shared-key", 0, 1)
    assert {:ok, _result} = execute(context, operator, original)

    assert {:error, %{"error" => %{"code" => "idempotency-conflict"}}} =
             execute(context, operator, %{original | "correlation_id" => "changed"})

    assert {:error, %{"error" => %{"code" => "command-invalid"}}} =
             execute(context, operator, Map.delete(command("bad", "bad-key", 1, 1), "schema"))

    assert CommandExecution.snapshot(context.executions)["resource"]["value"] == 1
  end

  test "capacity denies new work while exact replay remains available", context do
    suffix = System.unique_integer([:positive])
    executions = Module.concat(__MODULE__, "Small#{suffix}")

    start_supervised!(%{
      id: {:small_execution, suffix},
      start:
        {CommandExecution, :start_link,
         [[name: executions, max_executions: 1, max_per_session: 1]]}
    })

    context = %{context | executions: executions}
    first = session(context, "operator")
    request = command("one", "one-key", 0, 1)

    assert {:ok, _result} = execute(context, first, request)
    assert {:ok, %{"result" => %{"replayed" => true}}} = execute(context, first, request)

    second = session(context, "operator")

    assert {:error, %{"error" => %{"code" => "execution-capacity"}}} =
             execute(context, second, command("two", "two-key", 1, 1))
  end

  test "session revocation removes private records without reverting resource state", context do
    session = session(context, "operator")
    assert {:ok, _result} = execute(context, session, command("one", "one-key", 0, 1))
    assert :ok = CommandExecution.revoke_session(session["session_id"], context.executions)

    snapshot = CommandExecution.snapshot(context.executions)
    assert snapshot["executions"] == 0
    assert snapshot["tracked_sessions"] == 0
    assert snapshot["resource"]["value"] == 1
  end

  test "audit is bounded, monotonic, and redacted", context do
    suffix = System.unique_integer([:positive])
    executions = Module.concat(__MODULE__, "Audit#{suffix}")

    start_supervised!(%{
      id: {:audit_execution, suffix},
      start: {CommandExecution, :start_link, [[name: executions, max_audit: 2]]}
    })

    context = %{context | executions: executions}
    session = session(context, "operator")

    assert {:ok, _} = execute(context, session, command("one", "secret-one", 0, 1))
    assert {:ok, _} = execute(context, session, command("two", "secret-two", 1, 1))
    assert {:ok, _} = execute(context, session, command("three", "secret-three", 2, 1))

    snapshot = CommandExecution.snapshot(executions)
    assert Enum.map(snapshot["audit"], & &1["sequence"]) == [2, 3]
    refute inspect(snapshot) =~ session["session_id"]
    refute inspect(snapshot) =~ session["csrf_token"]
    refute inspect(snapshot) =~ "secret-"
  end

  test "concurrent exact requests apply one mutation", context do
    session = session(context, "operator")
    request = command("concurrent", "concurrent-key", 0, 1)

    results =
      1..20
      |> Task.async_stream(fn _ -> execute(context, session, request) end,
        max_concurrency: 20,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.count(results, &match?({:ok, %{"result" => %{"replayed" => false}}}, &1)) == 1
    assert Enum.count(results, &match?({:ok, %{"result" => %{"replayed" => true}}}, &1)) == 19
    assert CommandExecution.snapshot(context.executions)["resource"]["value"] == 1
  end

  test "reset clears execution state and advances generation", context do
    session = session(context, "operator")
    assert {:ok, _} = execute(context, session, command("one", "one-key", 0, 1))

    assert %{"generation" => 2, "executions" => 0, "resource" => %{"value" => 0}} =
             CommandExecution.reset(context.executions)
  end

  test "fresh execution pushes once while exact replay and failures stay silent", context do
    session = session(context, "operator")

    assert {:ok, %{"mode" => "replay", "cursor" => 0, "events" => []}} =
             subscribe(context, session, 0)

    request = command("push", "push-key", 0, 2)
    assert {:ok, _result} = execute(context, session, request)

    assert_receive {:blazex_counter_update,
                    %{
                      "protocol" => "blazex.bh07.counter-update/1",
                      "sequence" => 1,
                      "resource" => %{"value" => 2, "revision" => 1}
                    }}

    assert {:ok, _replay} = execute(context, session, request)
    refute_receive {:blazex_counter_update, _event}

    assert {:error, _stale} =
             execute(context, session, command("stale", "stale-key", 9, 1))

    refute_receive {:blazex_counter_update, _event}
    assert CommandExecution.snapshot(context.executions)["event_sequence"] == 1
  end

  test "cursor returns retained replay or current snapshot and rejects future", context do
    executions = Module.concat(__MODULE__, "Events#{System.unique_integer([:positive])}")
    start_unlinked_execution(executions, max_events: 2)
    context = %{context | executions: executions}
    session = session(context, "operator")

    for index <- 0..2 do
      assert {:ok, _result} =
               execute(
                 context,
                 session,
                 command("event-#{index}", "event-key-#{index}", index, 1)
               )
    end

    assert {:ok, %{"mode" => "replay", "cursor" => 3, "events" => events}} =
             subscribe(context, session, 1)

    assert Enum.map(events, & &1["sequence"]) == [2, 3]

    assert {:ok, %{"mode" => "snapshot", "cursor" => 3, "resource" => resource}} =
             subscribe(context, session, 0)

    assert resource == %{"id" => "counter", "value" => 3, "revision" => 3}
    assert {:error, "push-cursor-invalid"} = subscribe(context, session, 4)
  end

  test "subscriber capacity, replacement, process monitoring, and unsubscribe are bounded",
       context do
    executions = Module.concat(__MODULE__, "Subscribers#{System.unique_integer([:positive])}")
    start_unlinked_execution(executions, max_subscribers: 1)
    context = %{context | executions: executions}
    session = session(context, "operator")

    owner = spawn(fn -> Process.sleep(:infinity) end)
    second = spawn(fn -> Process.sleep(:infinity) end)
    on_exit(fn -> Process.exit(second, :kill) end)

    assert {:ok, _sync} =
             CommandExecution.subscribe(session["session_id"], session["csrf_token"], 0, owner,
               server: executions,
               session_server: context.sessions
             )

    assert {:ok, _replacement} =
             CommandExecution.subscribe(session["session_id"], session["csrf_token"], 0, owner,
               server: executions,
               session_server: context.sessions
             )

    assert {:error, "push-capacity"} =
             CommandExecution.subscribe(session["session_id"], session["csrf_token"], 0, second,
               server: executions,
               session_server: context.sessions
             )

    Process.exit(owner, :kill)
    await(fn -> CommandExecution.snapshot(executions)["subscribers"] == 0 end)

    assert {:ok, _sync} =
             CommandExecution.subscribe(session["session_id"], session["csrf_token"], 0, self(),
               server: executions,
               session_server: context.sessions
             )

    assert :ok = CommandExecution.unsubscribe(self(), executions)
    assert CommandExecution.snapshot(executions)["subscribers"] == 0
  end

  test "expired and revoked subscribers are removed before later push", context do
    expiring = session(context, "operator", now_ms: 1_000, ttl_ms: 100)

    assert {:ok, _sync} =
             CommandExecution.subscribe(
               expiring["session_id"],
               expiring["csrf_token"],
               0,
               self(),
               server: context.executions,
               session_server: context.sessions,
               now_ms: 1_050
             )

    fresh = session(context, "operator", now_ms: 1_050, ttl_ms: 1_000)

    assert {:ok, _result} =
             execute(context, fresh, command("expiry", "expiry-key", 0, 1), now_ms: 1_100)

    refute_receive {:blazex_counter_update, _event}
    assert CommandExecution.snapshot(context.executions)["subscribers"] == 0

    assert {:ok, _sync} =
             CommandExecution.subscribe(
               fresh["session_id"],
               fresh["csrf_token"],
               1,
               self(),
               server: context.executions,
               session_server: context.sessions,
               now_ms: 1_100
             )

    assert :ok = CommandExecution.revoke_session(fresh["session_id"], context.executions)
    assert CommandExecution.snapshot(context.executions)["subscribers"] == 0
  end

  test "invalid limits fail startup" do
    assert {:error, :invalid_command_execution_config} =
             GenServer.start(CommandExecution, max_audit: 0)

    assert {:error, :invalid_command_execution_config} =
             GenServer.start(CommandExecution, max_executions: 1, max_per_session: 2)
  end

  defp admission_options(name) do
    [
      name: name,
      declarations: %{
        "counter.increment" => %{
          schema: "counter.increment",
          payload: %{"amount" => {:integer, 1, 10}}
        }
      },
      grants: %{"operator" => ["counter.increment"], "viewer" => []}
    ]
  end

  defp session(context, subject, options \\ []) do
    assert {:ok, value} =
             SessionRegistry.issue(
               subject,
               String.capitalize(subject),
               Keyword.put(options, :server, context.sessions)
             )

    value
  end

  defp execute(context, session, command, options \\ []) do
    CommandExecution.execute(session["session_id"], session["csrf_token"], command,
      server: context.executions,
      admission_server: context.admissions,
      session_server: context.sessions,
      now_ms: Keyword.get(options, :now_ms, System.system_time(:millisecond))
    )
  end

  defp subscribe(context, session, after_sequence) do
    CommandExecution.subscribe(
      session["session_id"],
      session["csrf_token"],
      after_sequence,
      self(),
      server: context.executions,
      session_server: context.sessions
    )
  end

  defp start_unlinked_execution(name, options) do
    suffix = System.unique_integer([:positive])

    start_supervised!(%{
      id: {:stream_execution, suffix},
      start: {CommandExecution, :start_link, [[name: name] ++ options]}
    })
  end

  defp await(predicate, attempts \\ 20)
  defp await(predicate, 0), do: assert(predicate.())

  defp await(predicate, attempts) do
    if predicate.() do
      :ok
    else
      Process.sleep(5)
      await(predicate, attempts - 1)
    end
  end

  defp command(correlation_id, idempotency_key, expected_revision, amount) do
    %{
      "protocol" => "blazex.bh07.command-intent/1",
      "command" => "counter.increment",
      "schema" => "counter.increment",
      "correlation_id" => correlation_id,
      "idempotency_key" => idempotency_key,
      "expected_revision" => expected_revision,
      "payload" => %{"amount" => amount}
    }
  end
end
