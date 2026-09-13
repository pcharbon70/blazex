defmodule BlazeX.Phoenix.CommandExecution do
  @moduledoc "Atomic execution of the closed BH-07 trusted counter command."
  use GenServer

  alias BlazeX.Phoenix.{CommandAdmission, SessionRegistry}

  @command "counter.increment"
  @schema "counter.increment"
  @result_protocol "blazex.bh07.command-result/1"
  @default_max_executions 256
  @default_max_per_session 32
  @default_max_audit 64

  def start_link(options \\ []) do
    name = Keyword.get(options, :name, __MODULE__)
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def execute(session_id, csrf_token, envelope, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    admission_server = Keyword.get(options, :admission_server, CommandAdmission)
    session_server = Keyword.get(options, :session_server, SessionRegistry)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))

    case CommandAdmission.admit(session_id, csrf_token, envelope,
           server: admission_server,
           session_server: session_server,
           now_ms: now_ms
         ) do
      {:ok, _receipt} -> GenServer.call(server, {:execute, session_id, envelope})
      {:error, code} -> {:error, error_result(code, correlation_id(envelope), false)}
    end
  end

  def snapshot(server \\ __MODULE__), do: GenServer.call(server, :snapshot)
  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  def revoke_session(session_id, server \\ __MODULE__) do
    if is_binary(session_id), do: GenServer.call(server, {:revoke_session, session_id}), else: :ok
  end

  @impl true
  def init(options) do
    max_executions = Keyword.get(options, :max_executions, @default_max_executions)
    max_per_session = Keyword.get(options, :max_per_session, @default_max_per_session)
    max_audit = Keyword.get(options, :max_audit, @default_max_audit)

    if valid_limits?(max_executions, max_per_session, max_audit) do
      {:ok, initial_state(max_executions, max_per_session, max_audit, 1)}
    else
      {:stop, :invalid_command_execution_config}
    end
  end

  @impl true
  def handle_call({:execute, session_id, envelope}, _from, state) do
    key = {session_id, envelope["idempotency_key"]}
    fingerprint = fingerprint(envelope)

    case Map.fetch(state.executions, key) do
      {:ok, %{fingerprint: ^fingerprint, response: response}} ->
        replay = mark_replayed(response)
        next = audit(state, envelope, replay_outcome(response), false)
        {:reply, reply(replay), next}

      {:ok, _record} ->
        response = error_result("idempotency-conflict", correlation_id(envelope), false)
        {:reply, {:error, response}, audit(state, envelope, "idempotency-conflict", false)}

      :error ->
        execute_new(state, key, fingerprint, envelope)
    end
  end

  def handle_call(:snapshot, _from, state), do: {:reply, public_snapshot(state), state}

  def handle_call({:revoke_session, session_id}, _from, state) do
    executions =
      Map.reject(state.executions, fn {{stored_session_id, _key}, _record} ->
        stored_session_id == session_id
      end)

    next = %{
      state
      | executions: executions,
        session_counts: Map.delete(state.session_counts, session_id)
    }

    {:reply, :ok, next}
  end

  def handle_call(:reset, _from, state) do
    next =
      initial_state(
        state.max_executions,
        state.max_per_session,
        state.max_audit,
        state.generation + 1
      )

    {:reply, public_snapshot(next), next}
  end

  defp execute_new(state, key, fingerprint, envelope) do
    with :ok <- require_capacity(state, elem(key, 0)),
         :ok <- require_closed_operation(envelope) do
      if envelope["expected_revision"] == state.resource.revision do
        apply_increment(state, key, fingerprint, envelope)
      else
        retain_stale(state, key, fingerprint, envelope)
      end
    else
      {:error, code} ->
        response = error_result(code, correlation_id(envelope), false)
        {:reply, {:error, response}, audit(state, envelope, code, false)}
    end
  end

  defp apply_increment(state, key, fingerprint, envelope) do
    resource = %{
      state.resource
      | value: state.resource.value + envelope["payload"]["amount"],
        revision: state.resource.revision + 1
    }

    response = success_result(envelope, resource)

    next =
      state
      |> Map.put(:resource, resource)
      |> retain(key, fingerprint, response)
      |> audit(envelope, "executed", true)

    {:reply, {:ok, response}, next}
  end

  defp retain_stale(state, key, fingerprint, envelope) do
    response = error_result("state-stale", correlation_id(envelope), false)

    next =
      state
      |> retain(key, fingerprint, response)
      |> audit(envelope, "state-stale", false)

    {:reply, {:error, response}, next}
  end

  defp retain(state, {session_id, _idempotency_key} = key, fingerprint, response) do
    %{
      state
      | executions:
          Map.put(state.executions, key, %{fingerprint: fingerprint, response: response}),
        session_counts: Map.update(state.session_counts, session_id, 1, &(&1 + 1))
    }
  end

  defp require_closed_operation(envelope) do
    case envelope do
      %{
        "command" => @command,
        "schema" => @schema,
        "payload" => %{"amount" => amount}
      }
      when is_integer(amount) and amount in 1..10 ->
        :ok

      _ ->
        {:error, "execution-operation-invalid"}
    end
  end

  defp require_capacity(state, session_id) do
    cond do
      map_size(state.executions) >= state.max_executions ->
        {:error, "execution-capacity"}

      Map.get(state.session_counts, session_id, 0) >= state.max_per_session ->
        {:error, "execution-rate-limited"}

      true ->
        :ok
    end
  end

  defp success_result(envelope, resource) do
    %{
      "protocol" => @result_protocol,
      "status" => "ok",
      "correlation_id" => envelope["correlation_id"],
      "result" => %{
        "resource_id" => resource.id,
        "value" => resource.value,
        "revision" => resource.revision,
        "replayed" => false,
        "executed" => true
      }
    }
  end

  defp error_result(code, correlation_id, replayed) do
    %{
      "protocol" => @result_protocol,
      "status" => "error",
      "correlation_id" => correlation_id,
      "error" => %{
        "code" => code,
        "retryable" => false,
        "replayed" => replayed,
        "executed" => false
      }
    }
  end

  defp mark_replayed(%{"result" => result} = response),
    do: %{response | "result" => %{result | "replayed" => true}}

  defp mark_replayed(%{"error" => error} = response),
    do: %{response | "error" => %{error | "replayed" => true}}

  defp reply(%{"status" => "ok"} = response), do: {:ok, response}
  defp reply(response), do: {:error, response}

  defp replay_outcome(%{"status" => "ok"}), do: "replayed"
  defp replay_outcome(_response), do: "failure-replayed"

  defp audit(state, envelope, outcome, mutated) do
    event = %{
      "protocol" => "blazex.bh07.command-audit/1",
      "sequence" => state.audit_sequence + 1,
      "command" => envelope["command"],
      "correlation_id" => correlation_id(envelope),
      "outcome" => outcome,
      "mutation_applied" => mutated,
      "resource_revision" => state.resource.revision,
      "idempotency_digest" => idempotency_digest(envelope)
    }

    %{
      state
      | audit: Enum.take(state.audit ++ [event], -state.max_audit),
        audit_sequence: state.audit_sequence + 1
    }
  end

  defp public_snapshot(state) do
    %{
      "protocol" => "blazex.bh07.command-state/1",
      "generation" => state.generation,
      "resource" => %{
        "id" => state.resource.id,
        "value" => state.resource.value,
        "revision" => state.resource.revision
      },
      "executions" => map_size(state.executions),
      "capacity" => state.max_executions,
      "max_per_session" => state.max_per_session,
      "tracked_sessions" => map_size(state.session_counts),
      "audit" => state.audit
    }
  end

  defp initial_state(max_executions, max_per_session, max_audit, generation) do
    %{
      resource: %{id: "counter", value: 0, revision: 0},
      executions: %{},
      session_counts: %{},
      audit: [],
      audit_sequence: 0,
      max_executions: max_executions,
      max_per_session: max_per_session,
      max_audit: max_audit,
      generation: generation
    }
  end

  defp valid_limits?(max_executions, max_per_session, max_audit) do
    is_integer(max_executions) and max_executions in 1..@default_max_executions and
      is_integer(max_per_session) and max_per_session in 1..@default_max_per_session and
      max_per_session <= max_executions and is_integer(max_audit) and
      max_audit in 1..@default_max_audit
  end

  defp fingerprint(envelope),
    do: :crypto.hash(:sha256, :erlang.term_to_binary(envelope, [:deterministic]))

  defp idempotency_digest(%{"idempotency_key" => key}) when is_binary(key),
    do: :sha256 |> :crypto.hash(key) |> Base.encode16(case: :lower) |> binary_part(0, 16)

  defp idempotency_digest(_envelope), do: "unavailable"

  defp correlation_id(%{"correlation_id" => value}) when is_binary(value), do: value
  defp correlation_id(_envelope), do: "unavailable"
end
