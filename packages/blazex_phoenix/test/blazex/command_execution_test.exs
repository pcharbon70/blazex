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

  defp session(context, subject) do
    assert {:ok, value} =
             SessionRegistry.issue(subject, String.capitalize(subject), server: context.sessions)

    value
  end

  defp execute(context, session, command) do
    CommandExecution.execute(session["session_id"], session["csrf_token"], command,
      server: context.executions,
      admission_server: context.admissions,
      session_server: context.sessions
    )
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
