defmodule BlazeX.Phoenix.BH01.FixtureAuthority do
  @moduledoc false
  use GenServer

  @identities %{
    "operator" => %{role: "operator", enabled: true, allowed_actions: ["counter.increment"]},
    "viewer" => %{role: "viewer", enabled: true, allowed_actions: []},
    "disabled" => %{role: "operator", enabled: false, allowed_actions: []}
  }

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
    result =
      with true <- is_binary(session_id) and is_binary(csrf_token),
           {:ok, session} <- Map.fetch(state.sessions, session_id),
           false <- session.revoked,
           true <- now_ms < session.expires_at_ms,
           true <- secure_equal?(digest(csrf_token), session.csrf_sha256),
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
        true -> {:error, "session-invalid"}
        false -> {:error, "session-invalid"}
        :error -> {:error, "session-invalid"}
        {:error, _} -> {:error, "session-invalid"}
      end

    {:reply, result, state}
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
