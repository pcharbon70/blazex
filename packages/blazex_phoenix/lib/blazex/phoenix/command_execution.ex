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
  @default_max_events 64
  @default_max_subscribers 64
  @max_safe_integer 9_007_199_254_740_991

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
      {:ok, _receipt} -> GenServer.call(server, {:execute, session_id, envelope, now_ms})
      {:error, code} -> {:error, error_result(code, correlation_id(envelope), false)}
    end
  end

  def subscribe(session_id, csrf_token, after_sequence, subscriber \\ self(), options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    session_server = Keyword.get(options, :session_server, SessionRegistry)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))

    with true <- is_pid(subscriber),
         true <- is_integer(after_sequence) and after_sequence in 0..@max_safe_integer,
         {:ok, context} <-
           SessionRegistry.authority_context(session_id, csrf_token,
             server: session_server,
             now_ms: now_ms
           ) do
      GenServer.call(server, {:subscribe, context, after_sequence, subscriber, now_ms})
    else
      false -> {:error, "push-subscription-invalid"}
      {:error, code} -> {:error, code}
    end
  end

  def unsubscribe(subscriber \\ self(), server \\ __MODULE__) do
    if is_pid(subscriber), do: GenServer.call(server, {:unsubscribe, subscriber}), else: :ok
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
    max_events = Keyword.get(options, :max_events, @default_max_events)
    max_subscribers = Keyword.get(options, :max_subscribers, @default_max_subscribers)

    if valid_limits?(max_executions, max_per_session, max_audit, max_events, max_subscribers) do
      {:ok,
       initial_state(
         max_executions,
         max_per_session,
         max_audit,
         max_events,
         max_subscribers,
         1
       )}
    else
      {:stop, :invalid_command_execution_config}
    end
  end

  @impl true
  def handle_call({:execute, session_id, envelope, now_ms}, _from, state) do
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
        execute_new(state, key, fingerprint, envelope, now_ms)
    end
  end

  def handle_call({:subscribe, context, after_sequence, subscriber, now_ms}, _from, state) do
    state = prune_expired_subscribers(state, now_ms)

    with {:ok, sync} <- sync(state, after_sequence),
         :ok <- require_subscriber_capacity(state, subscriber) do
      next = put_subscriber(state, subscriber, context)
      {:reply, {:ok, sync}, next}
    else
      {:error, code} -> {:reply, {:error, code}, state}
    end
  end

  def handle_call({:unsubscribe, subscriber}, _from, state) do
    {:reply, :ok, drop_subscriber(state, subscriber)}
  end

  def handle_call(:snapshot, _from, state), do: {:reply, public_snapshot(state), state}

  def handle_call({:revoke_session, session_id}, _from, state) do
    executions =
      Map.reject(state.executions, fn {{stored_session_id, _key}, _record} ->
        stored_session_id == session_id
      end)

    next =
      state
      |> Map.put(:executions, executions)
      |> Map.put(:session_counts, Map.delete(state.session_counts, session_id))
      |> drop_session_subscribers(session_id)

    {:reply, :ok, next}
  end

  def handle_call(:reset, _from, state) do
    Enum.each(state.subscribers, fn {_pid, record} ->
      Process.demonitor(record.monitor, [:flush])
    end)

    next =
      initial_state(
        state.max_executions,
        state.max_per_session,
        state.max_audit,
        state.max_events,
        state.max_subscribers,
        state.generation + 1
      )

    {:reply, public_snapshot(next), next}
  end

  @impl true
  def handle_info({:DOWN, monitor, :process, subscriber, _reason}, state) do
    case Map.get(state.subscribers, subscriber) do
      %{monitor: ^monitor} ->
        {:noreply, %{state | subscribers: Map.delete(state.subscribers, subscriber)}}

      _record ->
        {:noreply, state}
    end
  end

  defp execute_new(state, key, fingerprint, envelope, now_ms) do
    with :ok <- require_capacity(state, elem(key, 0)),
         :ok <- require_closed_operation(envelope) do
      if envelope["expected_revision"] == state.resource.revision do
        apply_increment(state, key, fingerprint, envelope, now_ms)
      else
        retain_stale(state, key, fingerprint, envelope)
      end
    else
      {:error, code} ->
        response = error_result(code, correlation_id(envelope), false)
        {:reply, {:error, response}, audit(state, envelope, code, false)}
    end
  end

  defp apply_increment(state, key, fingerprint, envelope, now_ms) do
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
      |> publish(resource, now_ms)

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
      "audit" => state.audit,
      "event_sequence" => state.event_sequence,
      "retained_events" => length(state.events),
      "event_capacity" => state.max_events,
      "subscribers" => map_size(state.subscribers),
      "subscriber_capacity" => state.max_subscribers
    }
  end

  defp initial_state(
         max_executions,
         max_per_session,
         max_audit,
         max_events,
         max_subscribers,
         generation
       ) do
    %{
      resource: %{id: "counter", value: 0, revision: 0},
      executions: %{},
      session_counts: %{},
      audit: [],
      audit_sequence: 0,
      events: [],
      event_sequence: 0,
      subscribers: %{},
      max_executions: max_executions,
      max_per_session: max_per_session,
      max_audit: max_audit,
      max_events: max_events,
      max_subscribers: max_subscribers,
      generation: generation
    }
  end

  defp valid_limits?(max_executions, max_per_session, max_audit, max_events, max_subscribers) do
    is_integer(max_executions) and max_executions in 1..@default_max_executions and
      is_integer(max_per_session) and max_per_session in 1..@default_max_per_session and
      max_per_session <= max_executions and is_integer(max_audit) and
      max_audit in 1..@default_max_audit and is_integer(max_events) and
      max_events in 1..@default_max_events and is_integer(max_subscribers) and
      max_subscribers in 1..@default_max_subscribers
  end

  defp publish(state, resource, now_ms) do
    event = %{
      "protocol" => "blazex.bh07.counter-update/1",
      "sequence" => state.event_sequence + 1,
      "resource" => %{
        "id" => resource.id,
        "value" => resource.value,
        "revision" => resource.revision
      }
    }

    next =
      state
      |> Map.put(:events, Enum.take(state.events ++ [event], -state.max_events))
      |> Map.put(:event_sequence, state.event_sequence + 1)
      |> prune_expired_subscribers(now_ms)

    Enum.each(next.subscribers, fn {subscriber, _record} ->
      send(subscriber, {:blazex_counter_update, event})
    end)

    next
  end

  defp sync(state, after_sequence) when after_sequence > state.event_sequence,
    do: {:error, "push-cursor-invalid"}

  defp sync(state, after_sequence) do
    oldest =
      case state.events do
        [%{"sequence" => sequence} | _rest] -> sequence
        [] -> state.event_sequence + 1
      end

    if after_sequence < oldest - 1 do
      {:ok,
       %{
         "protocol" => "blazex.bh07.push-sync/1",
         "mode" => "snapshot",
         "cursor" => state.event_sequence,
         "events" => [],
         "resource" => %{
           "id" => state.resource.id,
           "value" => state.resource.value,
           "revision" => state.resource.revision
         }
       }}
    else
      events = Enum.filter(state.events, &(&1["sequence"] > after_sequence))

      {:ok,
       %{
         "protocol" => "blazex.bh07.push-sync/1",
         "mode" => "replay",
         "cursor" => state.event_sequence,
         "events" => events,
         "resource" => nil
       }}
    end
  end

  defp require_subscriber_capacity(state, subscriber) do
    if Map.has_key?(state.subscribers, subscriber) or
         map_size(state.subscribers) < state.max_subscribers,
       do: :ok,
       else: {:error, "push-capacity"}
  end

  defp put_subscriber(state, subscriber, context) do
    state = drop_subscriber(state, subscriber)
    monitor = Process.monitor(subscriber)

    record = %{
      monitor: monitor,
      session_id: context.session_id,
      expires_at_ms: context.expires_at_ms
    }

    %{state | subscribers: Map.put(state.subscribers, subscriber, record)}
  end

  defp drop_subscriber(state, subscriber) do
    case Map.pop(state.subscribers, subscriber) do
      {nil, _subscribers} ->
        state

      {%{monitor: monitor}, subscribers} ->
        Process.demonitor(monitor, [:flush])
        %{state | subscribers: subscribers}
    end
  end

  defp drop_session_subscribers(state, session_id) do
    Enum.reduce(state.subscribers, state, fn {subscriber, record}, acc ->
      if record.session_id == session_id, do: drop_subscriber(acc, subscriber), else: acc
    end)
  end

  defp prune_expired_subscribers(state, now_ms) do
    Enum.reduce(state.subscribers, state, fn {subscriber, record}, acc ->
      if record.expires_at_ms <= now_ms, do: drop_subscriber(acc, subscriber), else: acc
    end)
  end

  defp fingerprint(envelope),
    do: :crypto.hash(:sha256, :erlang.term_to_binary(envelope, [:deterministic]))

  defp idempotency_digest(%{"idempotency_key" => key}) when is_binary(key),
    do: :sha256 |> :crypto.hash(key) |> Base.encode16(case: :lower) |> binary_part(0, 16)

  defp idempotency_digest(_envelope), do: "unavailable"

  defp correlation_id(%{"correlation_id" => value}) when is_binary(value), do: value
  defp correlation_id(_envelope), do: "unavailable"
end
