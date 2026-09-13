defmodule BlazeX.Phoenix.SessionRegistry do
  @moduledoc "Bounded server-owned opaque sessions for the Phoenix adapter."
  use GenServer

  @default_max_sessions 256
  @max_ttl_ms 3_600_000
  @subject_pattern ~r/\A[a-z0-9][a-z0-9_-]{0,63}\z/

  def start_link(options \\ []) do
    name = Keyword.get(options, :name, __MODULE__)
    max_sessions = Keyword.get(options, :max_sessions, @default_max_sessions)
    GenServer.start_link(__MODULE__, max_sessions, name: name)
  end

  def issue(subject_id, display_label, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))
    ttl_ms = Keyword.get(options, :ttl_ms, 900_000)

    with :ok <- validate_subject(subject_id, display_label),
         :ok <- validate_time(now_ms, ttl_ms) do
      GenServer.call(server, {:issue, subject_id, display_label, now_ms, ttl_ms})
    end
  end

  def lookup(session_id, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))

    if valid_session_id?(session_id) and is_integer(now_ms) do
      GenServer.call(server, {:lookup, session_id, now_ms})
    else
      {:error, "session-invalid"}
    end
  end

  def rotate(session_id, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))

    if valid_session_id?(session_id) and is_integer(now_ms) do
      GenServer.call(server, {:rotate, session_id, now_ms})
    else
      {:error, "session-invalid"}
    end
  end

  def revoke(session_id, server \\ __MODULE__) do
    if valid_session_id?(session_id), do: GenServer.call(server, {:revoke, session_id}), else: :ok
  end

  def snapshot(server \\ __MODULE__), do: GenServer.call(server, :snapshot)
  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  @impl true
  def init(max_sessions)
      when is_integer(max_sessions) and max_sessions > 0 and max_sessions <= @default_max_sessions do
    {:ok, %{sessions: %{}, max_sessions: max_sessions, generation: 1}}
  end

  def init(_max_sessions), do: {:stop, :invalid_max_sessions}

  @impl true
  def handle_call({:issue, subject_id, display_label, now_ms, ttl_ms}, _from, state) do
    state = prune(state, now_ms)

    if map_size(state.sessions) >= state.max_sessions do
      {:reply, {:error, "session-capacity"}, state}
    else
      {session_id, sessions} =
        put_new_session(state.sessions, subject_id, display_label, now_ms + ttl_ms)

      record = Map.fetch!(sessions, session_id)
      {:reply, {:ok, issued(session_id, record)}, %{state | sessions: sessions}}
    end
  end

  def handle_call({:lookup, session_id, now_ms}, _from, state) do
    state = prune(state, now_ms)

    case Map.fetch(state.sessions, session_id) do
      {:ok, record} -> {:reply, {:ok, projection(record)}, state}
      :error -> {:reply, {:error, "session-invalid"}, state}
    end
  end

  def handle_call({:rotate, session_id, now_ms}, _from, state) do
    state = prune(state, now_ms)

    case Map.pop(state.sessions, session_id) do
      {nil, _sessions} ->
        {:reply, {:error, "session-invalid"}, state}

      {record, sessions} ->
        {new_id, sessions} =
          put_new_session(sessions, record.subject_id, record.display_label, record.expires_at_ms)

        {:reply, {:ok, issued(new_id, record)}, %{state | sessions: sessions}}
    end
  end

  def handle_call({:revoke, session_id}, _from, state) do
    {:reply, :ok, %{state | sessions: Map.delete(state.sessions, session_id)}}
  end

  def handle_call(:snapshot, _from, state), do: {:reply, public_snapshot(state), state}

  def handle_call(:reset, _from, state) do
    next = %{state | sessions: %{}, generation: state.generation + 1}
    {:reply, public_snapshot(next), next}
  end

  defp issued(session_id, record),
    do: %{"session_id" => session_id, "projection" => projection(record)}

  defp projection(record) do
    %{
      "protocol" => "blazex.bh07.session/1",
      "state" => "authenticated",
      "subject" => record.display_label,
      "expires_at_ms" => record.expires_at_ms
    }
  end

  defp public_snapshot(state) do
    %{
      "active_sessions" => map_size(state.sessions),
      "capacity" => state.max_sessions,
      "generation" => state.generation
    }
  end

  defp prune(state, now_ms) do
    sessions = Map.reject(state.sessions, fn {_id, record} -> record.expires_at_ms <= now_ms end)
    %{state | sessions: sessions}
  end

  defp put_new_session(sessions, subject_id, display_label, expires_at_ms) do
    session_id = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    if Map.has_key?(sessions, session_id) do
      put_new_session(sessions, subject_id, display_label, expires_at_ms)
    else
      record = %{
        subject_id: subject_id,
        display_label: display_label,
        expires_at_ms: expires_at_ms
      }

      {session_id, Map.put(sessions, session_id, record)}
    end
  end

  defp validate_subject(subject_id, display_label)
       when is_binary(subject_id) and is_binary(display_label) do
    if Regex.match?(@subject_pattern, subject_id) and String.valid?(display_label) and
         byte_size(display_label) in 1..80 and
         not String.contains?(display_label, ["\0", "\n", "\r"]) do
      :ok
    else
      {:error, "session-subject-invalid"}
    end
  end

  defp validate_subject(_subject_id, _display_label), do: {:error, "session-subject-invalid"}

  defp validate_time(now_ms, ttl_ms)
       when is_integer(now_ms) and is_integer(ttl_ms) and ttl_ms in 1..@max_ttl_ms,
       do: :ok

  defp validate_time(_now_ms, _ttl_ms), do: {:error, "session-ttl-invalid"}

  defp valid_session_id?(value), do: is_binary(value) and byte_size(value) == 43
end
