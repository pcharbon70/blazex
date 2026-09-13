defmodule BlazeX.Phoenix.CommandAdmission do
  @moduledoc "Bounded typed command admission without handler execution."
  use GenServer

  alias BlazeX.Phoenix.SessionRegistry

  @protocol "blazex.bh07.command-intent/1"
  @result_protocol "blazex.bh07.command-admission/1"
  @fields ~w(command correlation_id expected_revision idempotency_key payload protocol schema)
  @name_pattern ~r/\A[a-z][a-z0-9_.-]{0,63}\z/
  @identifier_pattern ~r/\A[A-Za-z0-9][A-Za-z0-9._:-]{0,63}\z/
  @subject_pattern ~r/\A[a-z0-9][a-z0-9_-]{0,63}\z/
  @max_safe_integer 9_007_199_254_740_991
  @default_max_admissions 256
  @default_max_per_session 32

  def start_link(options) do
    name = Keyword.get(options, :name, __MODULE__)
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def admit(session_id, csrf_token, envelope, options \\ []) do
    server = Keyword.get(options, :server, __MODULE__)
    session_server = Keyword.get(options, :session_server, SessionRegistry)
    now_ms = Keyword.get(options, :now_ms, System.system_time(:millisecond))

    with {:ok, command} <- validate_envelope(envelope),
         {:ok, context} <-
           SessionRegistry.authority_context(session_id, csrf_token,
             server: session_server,
             now_ms: now_ms
           ) do
      GenServer.call(server, {:admit, context, command})
    end
  end

  def snapshot(server \\ __MODULE__), do: GenServer.call(server, :snapshot)
  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  def revoke_session(session_id, server \\ __MODULE__) do
    if is_binary(session_id), do: GenServer.call(server, {:revoke_session, session_id}), else: :ok
  end

  @impl true
  def init(options) do
    declarations = Keyword.get(options, :declarations, %{})
    grants = Keyword.get(options, :grants, %{})
    max_admissions = Keyword.get(options, :max_admissions, @default_max_admissions)
    max_per_session = Keyword.get(options, :max_per_session, @default_max_per_session)

    if valid_config?(declarations, grants, max_admissions, max_per_session) do
      {:ok,
       %{
         declarations: declarations,
         grants: grants,
         admissions: %{},
         session_counts: %{},
         max_admissions: max_admissions,
         max_per_session: max_per_session,
         generation: 1
       }}
    else
      {:stop, :invalid_command_admission_config}
    end
  end

  @impl true
  def handle_call({:admit, context, command}, _from, state) do
    key = {context.session_id, command.idempotency_key}
    fingerprint = fingerprint(command.envelope)

    case Map.fetch(state.admissions, key) do
      {:ok, %{fingerprint: ^fingerprint, receipt: receipt}} ->
        {:reply, {:ok, put_in(receipt, ["receipt", "replayed"], true)}, state}

      {:ok, _record} ->
        {:reply, {:error, "idempotency-conflict"}, state}

      :error ->
        admit_new(state, key, fingerprint, context, command)
    end
  end

  def handle_call(:snapshot, _from, state), do: {:reply, public_snapshot(state), state}

  def handle_call({:revoke_session, session_id}, _from, state) do
    admissions =
      Map.reject(state.admissions, fn {{stored_session_id, _key}, _record} ->
        stored_session_id == session_id
      end)

    next = %{
      state
      | admissions: admissions,
        session_counts: Map.delete(state.session_counts, session_id)
    }

    {:reply, :ok, next}
  end

  def handle_call(:reset, _from, state) do
    next = %{state | admissions: %{}, session_counts: %{}, generation: state.generation + 1}
    {:reply, public_snapshot(next), next}
  end

  defp admit_new(state, key, fingerprint, context, command) do
    with {:ok, declaration} <- fetch_declaration(state.declarations, command.command),
         :ok <- require_schema(declaration, command.schema),
         :ok <- validate_payload(command.payload, declaration.payload),
         :ok <- authorize(state.grants, context.subject_id, command.command),
         :ok <- require_capacity(state, context.session_id) do
      receipt = receipt(command)

      next = %{
        state
        | admissions:
            Map.put(state.admissions, key, %{fingerprint: fingerprint, receipt: receipt}),
          session_counts:
            Map.update(state.session_counts, context.session_id, 1, fn count -> count + 1 end)
      }

      {:reply, {:ok, receipt}, next}
    else
      {:error, code} -> {:reply, {:error, code}, state}
    end
  end

  defp validate_envelope(envelope) when is_map(envelope) do
    with true <- Enum.sort(Map.keys(envelope)) == @fields,
         true <- envelope["protocol"] == @protocol,
         true <- valid_name?(envelope["command"]),
         true <- valid_name?(envelope["schema"]),
         true <- valid_identifier?(envelope["correlation_id"]),
         true <- valid_identifier?(envelope["idempotency_key"]),
         revision when is_integer(revision) and revision in 0..@max_safe_integer <-
           envelope["expected_revision"],
         payload when is_map(payload) and map_size(payload) <= 16 <- envelope["payload"],
         true <- byte_size(:erlang.term_to_binary(envelope, [:deterministic])) <= 2_048 do
      {:ok,
       %{
         command: envelope["command"],
         schema: envelope["schema"],
         correlation_id: envelope["correlation_id"],
         idempotency_key: envelope["idempotency_key"],
         expected_revision: revision,
         payload: payload,
         envelope: envelope
       }}
    else
      _ -> {:error, "command-invalid"}
    end
  end

  defp validate_envelope(_envelope), do: {:error, "command-invalid"}

  defp valid_config?(declarations, grants, max_admissions, max_per_session) do
    is_map(declarations) and map_size(declarations) in 1..32 and
      Enum.all?(declarations, &valid_declaration?/1) and
      is_map(grants) and map_size(grants) <= 64 and
      Enum.all?(grants, &valid_grant?(&1, declarations)) and
      is_integer(max_admissions) and max_admissions in 1..@default_max_admissions and
      is_integer(max_per_session) and max_per_session in 1..@default_max_per_session and
      max_per_session <= max_admissions
  end

  defp valid_declaration?({command, declaration}) do
    valid_name?(command) and is_map(declaration) and
      Enum.sort(Map.keys(declaration)) == [:payload, :schema] and
      valid_name?(declaration.schema) and valid_payload_schema?(declaration.payload)
  end

  defp valid_payload_schema?(schema) when is_map(schema) and map_size(schema) <= 16 do
    Enum.all?(schema, fn {name, descriptor} ->
      valid_name?(name) and valid_descriptor?(descriptor)
    end)
  end

  defp valid_payload_schema?(_schema), do: false

  defp valid_descriptor?(:boolean), do: true

  defp valid_descriptor?({:integer, minimum, maximum}),
    do: is_integer(minimum) and is_integer(maximum) and minimum <= maximum

  defp valid_descriptor?({:string, minimum, maximum}),
    do:
      is_integer(minimum) and is_integer(maximum) and minimum >= 0 and minimum <= maximum and
        maximum <= 256

  defp valid_descriptor?(_descriptor), do: false

  defp valid_grant?({subject, commands}, declarations) do
    is_binary(subject) and Regex.match?(@subject_pattern, subject) and is_list(commands) and
      length(commands) <= 32 and length(commands) == length(Enum.uniq(commands)) and
      Enum.all?(commands, &Map.has_key?(declarations, &1))
  end

  defp fetch_declaration(declarations, command) do
    case Map.fetch(declarations, command) do
      {:ok, declaration} -> {:ok, declaration}
      :error -> {:error, "command-unknown"}
    end
  end

  defp require_schema(declaration, schema),
    do: if(declaration.schema == schema, do: :ok, else: {:error, "command-schema-invalid"})

  defp validate_payload(payload, schema) do
    if Enum.sort(Map.keys(payload)) == Enum.sort(Map.keys(schema)) and
         Enum.all?(schema, fn {field, descriptor} -> valid_value?(payload[field], descriptor) end) do
      :ok
    else
      {:error, "command-payload-invalid"}
    end
  end

  defp valid_value?(value, :boolean), do: is_boolean(value)

  defp valid_value?(value, {:integer, minimum, maximum}),
    do: is_integer(value) and value in minimum..maximum

  defp valid_value?(value, {:string, minimum, maximum}),
    do: is_binary(value) and String.valid?(value) and byte_size(value) in minimum..maximum

  defp authorize(grants, subject, command) do
    if command in Map.get(grants, subject, []),
      do: :ok,
      else: {:error, "authorization-denied"}
  end

  defp require_capacity(state, session_id) do
    cond do
      map_size(state.admissions) >= state.max_admissions ->
        {:error, "admission-capacity"}

      Map.get(state.session_counts, session_id, 0) >= state.max_per_session ->
        {:error, "admission-rate-limited"}

      true ->
        :ok
    end
  end

  defp receipt(command) do
    %{
      "protocol" => @result_protocol,
      "status" => "admitted",
      "correlation_id" => command.correlation_id,
      "receipt" => %{
        "command" => command.command,
        "schema" => command.schema,
        "expected_revision" => command.expected_revision,
        "replayed" => false,
        "executed" => false
      }
    }
  end

  defp public_snapshot(state) do
    %{
      "admissions" => map_size(state.admissions),
      "capacity" => state.max_admissions,
      "max_per_session" => state.max_per_session,
      "tracked_sessions" => map_size(state.session_counts),
      "generation" => state.generation,
      "executed" => 0
    }
  end

  defp fingerprint(envelope),
    do: :crypto.hash(:sha256, :erlang.term_to_binary(envelope, [:deterministic]))

  defp valid_name?(value), do: is_binary(value) and Regex.match?(@name_pattern, value)
  defp valid_identifier?(value), do: is_binary(value) and Regex.match?(@identifier_pattern, value)
end
