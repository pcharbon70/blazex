defmodule BlazeX.Phoenix.BH01.FixtureAuthority do
  @moduledoc false
  use GenServer

  @identities %{
    "operator" => %{role: "operator", enabled: true, allowed_actions: ["counter.increment"]},
    "viewer" => %{role: "viewer", enabled: true, allowed_actions: []},
    "disabled" => %{role: "operator", enabled: false, allowed_actions: []}
  }

  @command_protocol "blazex.bh01.server-command/0.1"
  @result_protocol "blazex.bh01.server-result/0.1"
  @command_fields ~w(protocol command correlation_id idempotency_key resource_id expected_version payload)
  @rate_limit 3

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(options, :name, __MODULE__))
  end

  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  def issue_session(identity_id, options \\ []) when is_binary(identity_id) do
    server = Keyword.get(options, :server, __MODULE__)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))
    ttl_ms = Keyword.get(options, :ttl_ms, 60_000)
    GenServer.call(server, {:issue_session, identity_id, now_ms, ttl_ms})
  end

  def expire_session(session_id, server \\ __MODULE__) when is_binary(session_id),
    do: GenServer.call(server, {:expire_session, session_id})

  def authenticate(session_id, csrf_token, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))
    GenServer.call(server, {:authenticate, session_id, csrf_token, now_ms})
  end

  def execute(session_id, csrf_token, envelope, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))
    failure_mode = Keyword.get(options, :failure_mode, :none)
    GenServer.call(server, {:execute, session_id, csrf_token, envelope, now_ms, failure_mode})
  end

  def snapshot(server \\ __MODULE__), do: GenServer.call(server, :snapshot)

  @impl true
  def init(:ok), do: {:ok, initial_state(1)}

  @impl true
  def handle_call(:reset, _from, state) do
    next = initial_state(state.reset_generation + 1)
    {:reply, public_snapshot(next), next}
  end

  def handle_call({:issue_session, identity_id, now_ms, ttl_ms}, _from, state) do
    case Map.fetch(@identities, identity_id) do
      {:ok, identity}
      when identity.enabled and is_integer(ttl_ms) and ttl_ms in -60_000..300_000 ->
        session_id = token(24)
        csrf_token = token(32)
        expires_at_ms = now_ms + ttl_ms

        session = %{
          identity_id: identity_id,
          expires_at_ms: expires_at_ms,
          csrf_sha256: digest(csrf_token),
          revoked: false
        }

        next = put_in(state.sessions[session_id], session)

        public = %{
          "identity_id" => identity_id,
          "session_id" => session_id,
          "csrf_token" => csrf_token,
          "expires_at_ms" => expires_at_ms
        }

        {:reply, {:ok, public}, next}

      {:ok, _identity} ->
        {:reply, {:error, "identity-disabled"}, state}

      :error ->
        {:reply, {:error, "identity-unknown"}, state}
    end
  end

  def handle_call({:expire_session, session_id}, _from, state) do
    case Map.fetch(state.sessions, session_id) do
      {:ok, session} ->
        next = put_in(state.sessions[session_id], %{session | revoked: true})
        {:reply, :ok, next}

      :error ->
        {:reply, :missing, state}
    end
  end

  def handle_call({:authenticate, session_id, csrf_token, now_ms}, _from, state) do
    result = authenticate_context(state, session_id, csrf_token, now_ms)

    {:reply, result, state}
  end

  def handle_call(
        {:execute, session_id, csrf_token, envelope, now_ms, failure_mode},
        _from,
        state
      ) do
    {reply, next} = execute_command(state, session_id, csrf_token, envelope, now_ms, failure_mode)
    {:reply, reply, next}
  end

  def handle_call(:snapshot, _from, state), do: {:reply, public_snapshot(state), state}

  defp initial_state(generation) do
    %{
      reset_generation: generation,
      sessions: %{},
      resource: %{id: "counter", value: 0, version: 0},
      idempotency: %{},
      rate: %{},
      audit: []
    }
  end

  defp execute_command(state, session_id, csrf_token, envelope, now_ms, failure_mode) do
    with {:ok, context} <- authenticate_context(state, session_id, csrf_token, now_ms),
         {:ok, command} <- validate_command(envelope),
         :ok <- authorize(context, command) do
      execute_authorized(state, context, command, failure_mode)
    else
      {:error, code} -> {{:error, command_error(code, correlation_id(envelope))}, state}
    end
  end

  defp execute_authorized(state, context, command, failure_mode) do
    idempotency_id = {context.session_id, command.idempotency_key}
    fingerprint = digest(:erlang.term_to_binary(command.envelope, [:deterministic]))

    case Map.fetch(state.idempotency, idempotency_id) do
      {:ok, %{fingerprint: ^fingerprint, response: response}} ->
        replay = put_in(response, ["result", "replayed"], true)
        next = audit(state, context, command, "replayed", false)
        {{:ok, replay}, next}

      {:ok, _different_request} ->
        failed(state, context, command, "idempotency-conflict", false)

      :error ->
        execute_fresh(state, context, command, fingerprint, failure_mode)
    end
  end

  defp execute_fresh(state, context, command, fingerprint, failure_mode) do
    count = Map.get(state.rate, context.session_id, 0)

    cond do
      count >= @rate_limit ->
        failed(state, context, command, "rate-limited", false)

      command.expected_version != state.resource.version ->
        next = increment_rate(state, context.session_id)
        failed(next, context, command, "state-stale", false)

      failure_mode == :server_error ->
        next = increment_rate(state, context.session_id)
        failed(next, context, command, "server-unavailable", false, true)

      failure_mode == :transaction_error ->
        next = increment_rate(state, context.session_id)
        failed(next, context, command, "transaction-failed", false, true)

      failure_mode != :none ->
        failed(state, context, command, "failure-mode-invalid", false)

      true ->
        resource = %{
          state.resource
          | value: state.resource.value + command.amount,
            version: state.resource.version + 1
        }

        response = command_success(command.correlation_id, resource)

        next =
          state
          |> Map.put(:resource, resource)
          |> increment_rate(context.session_id)
          |> put_in([:idempotency, {context.session_id, command.idempotency_key}], %{
            fingerprint: fingerprint,
            response: response
          })
          |> audit(context, command, "accepted", true)

        {{:ok, response}, next}
    end
  end

  defp failed(state, context, command, code, effect, retryable \\ false) do
    next = audit(state, context, command, code, effect)
    {{:error, command_error(code, command.correlation_id, retryable)}, next}
  end

  defp authenticate_context(state, session_id, csrf_token, now_ms) do
    cond do
      not is_binary(session_id) or byte_size(session_id) == 0 ->
        {:error, "authentication-required"}

      not is_binary(csrf_token) or byte_size(csrf_token) == 0 ->
        {:error, "csrf-invalid"}

      true ->
        case Map.fetch(state.sessions, session_id) do
          :error ->
            {:error, "session-invalid"}

          {:ok, %{revoked: true}} ->
            {:error, "session-invalid"}

          {:ok, session} when now_ms >= session.expires_at_ms ->
            {:error, "session-expired"}

          {:ok, session} ->
            with true <- secure_equal?(digest(csrf_token), session.csrf_sha256),
                 {:ok, identity} <- Map.fetch(@identities, session.identity_id),
                 true <- identity.enabled do
              {:ok,
               %{
                 identity_id: session.identity_id,
                 role: identity.role,
                 allowed_actions: identity.allowed_actions,
                 session_id: session_id,
                 expires_at_ms: session.expires_at_ms
               }}
            else
              false -> {:error, "csrf-invalid"}
              _ -> {:error, "session-invalid"}
            end
        end
    end
  end

  defp validate_command(envelope) when is_map(envelope) do
    cond do
      Enum.sort(Map.keys(envelope)) != Enum.sort(@command_fields) ->
        {:error, "command-invalid"}

      envelope["protocol"] != @command_protocol ->
        {:error, "command-invalid"}

      envelope["command"] != "counter.increment" ->
        {:error, "command-unknown"}

      true ->
        validate_counter_command(envelope)
    end
  end

  defp validate_command(_envelope), do: {:error, "command-invalid"}

  defp validate_counter_command(envelope) do
    with true <- valid_identifier?(envelope["correlation_id"]),
         true <- valid_identifier?(envelope["idempotency_key"]),
         "counter" <- envelope["resource_id"],
         version when is_integer(version) and version >= 0 and version <= 1_000_000 <-
           envelope["expected_version"],
         %{"amount" => 1} = payload <- envelope["payload"],
         ["amount"] <- Map.keys(payload) do
      {:ok,
       %{
         envelope: envelope,
         correlation_id: envelope["correlation_id"],
         idempotency_key: envelope["idempotency_key"],
         expected_version: version,
         amount: 1,
         action: "counter.increment"
       }}
    else
      _ -> {:error, "command-invalid"}
    end
  end

  defp authorize(context, command) do
    if command.action in context.allowed_actions,
      do: :ok,
      else: {:error, "authorization-denied"}
  end

  defp command_success(correlation_id, resource) do
    %{
      "protocol" => @result_protocol,
      "status" => "ok",
      "correlation_id" => correlation_id,
      "result" => %{
        "resource_id" => resource.id,
        "value" => resource.value,
        "version" => resource.version,
        "replayed" => false
      }
    }
  end

  defp command_error(code, correlation_id, retryable \\ false) do
    %{
      "protocol" => @result_protocol,
      "status" => "error",
      "correlation_id" => correlation_id,
      "error" => %{"code" => code, "retryable" => retryable}
    }
  end

  defp correlation_id(%{"correlation_id" => value})
       when is_binary(value) and byte_size(value) <= 64,
       do: value

  defp correlation_id(_), do: "unavailable"

  defp increment_rate(state, session_id),
    do: update_in(state, [:rate, session_id], fn count -> (count || 0) + 1 end)

  defp audit(state, context, command, outcome, effect) do
    event = %{
      "protocol" => "blazex.bh01.audit/0.1",
      "sequence" => length(state.audit) + 1,
      "identity_id" => context.identity_id,
      "correlation_id" => command.correlation_id,
      "command" => command.action,
      "outcome" => outcome,
      "effect_applied" => effect,
      "resource_version" => state.resource.version,
      "idempotency_digest" =>
        command.idempotency_key |> digest() |> Base.encode16(case: :lower) |> binary_part(0, 16)
    }

    %{state | audit: Enum.take(state.audit ++ [event], -64)}
  end

  defp valid_identifier?(value) when is_binary(value) and byte_size(value) in 1..64,
    do: String.match?(value, ~r/^[A-Za-z0-9][A-Za-z0-9._:-]*$/)

  defp valid_identifier?(_value), do: false

  defp public_snapshot(state) do
    %{
      "protocol" => "blazex.bh01.server-state/0.1",
      "reset_generation" => state.reset_generation,
      "active_sessions" =>
        Enum.count(state.sessions, fn {_id, session} -> not session.revoked end),
      "resource" => stringify_resource(state.resource),
      "idempotency_count" => map_size(state.idempotency),
      "rate_subject_count" => map_size(state.rate),
      "audit" => state.audit
    }
  end

  defp stringify_resource(resource),
    do: %{"id" => resource.id, "value" => resource.value, "version" => resource.version}

  defp token(bytes), do: bytes |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  defp digest(value), do: :crypto.hash(:sha256, value)

  defp secure_equal?(left, right) when byte_size(left) == byte_size(right) do
    left
    |> :crypto.exor(right)
    |> :binary.bin_to_list()
    |> Enum.reduce(0, fn byte, acc -> :erlang.bor(byte, acc) end)
    |> Kernel.==(0)
  end

  defp secure_equal?(_, _), do: false
end
