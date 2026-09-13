defmodule BlazeX.Phoenix.CommandAdmissionTest do
  use ExUnit.Case, async: true

  alias BlazeX.Phoenix.{CommandAdmission, SessionRegistry}

  setup do
    suffix = System.unique_integer([:positive])
    session_server = Module.concat(__MODULE__, "Sessions#{suffix}")
    admission_server = Module.concat(__MODULE__, "Admissions#{suffix}")
    start_supervised!({SessionRegistry, name: session_server, max_sessions: 8})

    start_supervised!(
      {CommandAdmission,
       name: admission_server,
       declarations: declarations(),
       grants: %{"operator" => ["counter.increment"], "viewer" => []},
       max_admissions: 3,
       max_per_session: 2}
    )

    %{sessions: session_server, admissions: admission_server}
  end

  test "admits an authorized typed intent and replays its receipt", context do
    session = session(context.sessions, "operator")
    command = command("correlation-one", "key-one")

    assert {:ok, first} = admit(context, session, command)
    assert first["status"] == "admitted"
    assert first["receipt"]["executed"] == false
    assert first["receipt"]["replayed"] == false

    assert {:ok, replay} = admit(context, session, command)
    assert replay["receipt"]["replayed"] == true
    assert CommandAdmission.snapshot(context.admissions)["admissions"] == 1
  end

  test "rejects a changed request under the same idempotency key", context do
    session = session(context.sessions, "operator")
    assert {:ok, _receipt} = admit(context, session, command("first", "same-key"))

    changed = %{command("changed", "same-key") | "expected_revision" => 1}
    assert {:error, "idempotency-conflict"} = admit(context, session, changed)
    assert CommandAdmission.snapshot(context.admissions)["admissions"] == 1
  end

  test "denies unknown commands, schemas, subjects, and authority hints", context do
    operator = session(context.sessions, "operator")
    viewer = session(context.sessions, "viewer")
    assert {:error, "authorization-denied"} = admit(context, viewer, command("viewer", "viewer"))

    unknown = %{command("unknown", "unknown") | "command" => "counter.delete"}
    assert {:error, "command-unknown"} = admit(context, operator, unknown)

    wrong_schema = %{command("schema", "schema") | "schema" => "counter.other"}
    assert {:error, "command-schema-invalid"} = admit(context, operator, wrong_schema)

    hinted = Map.put(command("hint", "hint"), "subject", "operator")
    assert {:error, "command-invalid"} = admit(context, operator, hinted)
    assert CommandAdmission.snapshot(context.admissions)["admissions"] == 0
  end

  test "closed payload schema rejects shape, type, and range changes", context do
    session = session(context.sessions, "operator")

    invalid = [
      %{},
      %{"amount" => 0},
      %{"amount" => 11},
      %{"amount" => 1.0},
      %{"amount" => 1, "role" => "operator"}
    ]

    for {payload, index} <- Enum.with_index(invalid) do
      envelope = %{command("payload-#{index}", "payload-#{index}") | "payload" => payload}
      assert {:error, "command-payload-invalid"} = admit(context, session, envelope)
    end
  end

  test "invalid, expired, and incorrect-CSRF sessions cannot admit", context do
    session = session(context.sessions, "operator", now_ms: 1_000, ttl_ms: 100)
    envelope = command("auth", "auth")

    assert {:error, "csrf-invalid"} =
             CommandAdmission.admit(session["session_id"], String.duplicate("x", 43), envelope,
               server: context.admissions,
               session_server: context.sessions,
               now_ms: 1_050
             )

    assert {:error, "session-invalid"} =
             CommandAdmission.admit(session["session_id"], session["csrf_token"], envelope,
               server: context.admissions,
               session_server: context.sessions,
               now_ms: 1_100
             )
  end

  test "enforces per-session and global unique-admission bounds", context do
    first = session(context.sessions, "operator")
    second = session(context.sessions, "operator")

    assert {:ok, _} = admit(context, first, command("one", "one"))
    assert {:ok, _} = admit(context, first, command("two", "two"))
    assert {:error, "admission-rate-limited"} = admit(context, first, command("three", "three"))
    assert {:ok, _} = admit(context, second, command("four", "four"))
    assert {:error, "admission-capacity"} = admit(context, second, command("five", "five"))
  end

  test "concurrent exact replay stores one admission", context do
    session = session(context.sessions, "operator")
    envelope = command("race", "race-key")

    results =
      1..20
      |> Task.async_stream(fn _ -> admit(context, session, envelope) end,
        max_concurrency: 20,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.all?(results, &match?({:ok, _receipt}, &1))

    assert Enum.count(results, fn {:ok, receipt} -> receipt["receipt"]["replayed"] == false end) ==
             1

    assert CommandAdmission.snapshot(context.admissions)["admissions"] == 1
  end

  test "snapshot and reset expose counts but no authority or raw input", context do
    session = session(context.sessions, "operator")
    envelope = command("redacted", "private-idempotency")
    assert {:ok, _} = admit(context, session, envelope)
    snapshot = CommandAdmission.snapshot(context.admissions)
    assert snapshot["executed"] == 0
    refute inspect(snapshot) =~ session["session_id"]
    refute inspect(snapshot) =~ session["csrf_token"]
    refute inspect(snapshot) =~ "private-idempotency"
    refute inspect(snapshot) =~ "operator"
    assert %{"admissions" => 0, "generation" => 2} = CommandAdmission.reset(context.admissions)
  end

  test "hostile public keys remain strings and cannot select runtime handlers", context do
    session = session(context.sessions, "operator")
    marker = "phase5_never_intern_#{System.unique_integer([:positive])}"
    envelope = Map.put(command("hostile", "hostile"), marker, "Elixir.System")
    assert {:error, "command-invalid"} = admit(context, session, envelope)
    assert_raise ArgumentError, fn -> String.to_existing_atom(marker) end
    assert CommandAdmission.snapshot(context.admissions)["executed"] == 0
  end

  defp declarations do
    %{
      "counter.increment" => %{
        schema: "counter.increment",
        payload: %{"amount" => {:integer, 1, 10}}
      }
    }
  end

  defp session(server, subject, options \\ []) do
    assert {:ok, issued} =
             SessionRegistry.issue(
               subject,
               String.capitalize(subject),
               Keyword.put(options, :server, server)
             )

    issued
  end

  defp admit(context, session, envelope) do
    CommandAdmission.admit(session["session_id"], session["csrf_token"], envelope,
      server: context.admissions,
      session_server: context.sessions
    )
  end

  defp command(correlation, idempotency) do
    %{
      "protocol" => "blazex.bh07.command-intent/1",
      "command" => "counter.increment",
      "schema" => "counter.increment",
      "correlation_id" => correlation,
      "idempotency_key" => idempotency,
      "expected_revision" => 0,
      "payload" => %{"amount" => 1}
    }
  end
end
