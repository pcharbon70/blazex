defmodule BlazeX.Component.Action do
  @moduledoc "Closed version-1 portable action records. Constructors validate data, never execute work or grant authority."
  alias BlazeX.Component.{Input, NestedTable, RootPort, RootSchedule, Schema}

  @kinds [
    :message,
    :timer_start,
    :timer_cancel,
    :effect_request,
    :effect_cancel,
    :resource_transfer,
    :resource_release,
    :command
  ]
  @forbidden ~w(module function transport url credentials credential password secret access_token authorization authentication authorized socket pid provider_handle)
  @statuses [
    :accepted,
    :denied,
    :completed,
    :failed,
    :timed_out,
    :canceled,
    :stale,
    :disconnected
  ]

  @type t :: %{
          version: 1,
          kind:
            :message
            | :timer_start
            | :timer_cancel
            | :effect_request
            | :effect_cancel
            | :resource_transfer
            | :resource_release
            | :command,
          id: binary(),
          sequence: pos_integer(),
          owner: map(),
          body: map()
        }

  def new(kind, id, sequence, owner, body) do
    record = %{version: 1, kind: kind, id: id, sequence: sequence, owner: owner, body: body}
    if valid?(record), do: {:ok, record}, else: {:error, :invalid_action}
  end

  def valid?(record) do
    keys?(record, [:version, :kind, :id, :sequence, :owner, :body]) and record.version == 1 and
      record.kind in @kinds and Schema.name?(record.id) and positive?(record.sequence) and
      RootSchedule.identity?(record.owner) and public?(record) and size?(record, 16_384) and
      body?(record.kind, record.body)
  rescue
    _ -> false
  end

  def correlation(action, spec) do
    %{
      version: 1,
      handle: RootPort.handle(spec),
      owner: action.owner,
      id: action.id,
      sequence: action.sequence
    }
  end

  def correlation?(value),
    do:
      keys?(value, [:version, :handle, :owner, :id, :sequence]) and
        value.version == 1 and RootPort.handle?(value.handle) and
        RootSchedule.identity?(value.owner) and
        value.handle.root == value.owner.root and Schema.name?(value.id) and
        positive?(value.sequence)

  def result(correlation, status, value \\ nil, leases \\ []) do
    record = %{version: 1, correlation: correlation, status: status, value: value, leases: leases}
    if result?(record), do: {:ok, record}, else: {:error, :invalid_result}
  end

  def result?(record) do
    keys?(record, [:version, :correlation, :status, :value, :leases]) and record.version == 1 and
      correlation?(record.correlation) and record.status in @statuses and public?(record) and
      size?(record, 16_384) and
      is_list(record.leases) and length(record.leases) <= 16 and
      Enum.all?(record.leases, &Schema.name?/1) and
      Enum.uniq(record.leases) == record.leases and
      (record.status == :completed or record.leases == []) and
      (record.status in [:completed, :failed] or record.value == nil)
  rescue
    _ -> false
  end

  def lease?(value),
    do:
      keys?(value, [:id, :acquisition]) and Schema.name?(value.id) and
        correlation?(value.acquisition)

  def keys?(value, keys),
    do: is_map(value) and not is_struct(value) and Enum.sort(Map.keys(value)) == Enum.sort(keys)

  def positive?(n), do: NestedTable.counter?(n) and n > 0
  def size?(value, maximum), do: byte_size(:erlang.term_to_binary(value)) <= maximum
  def public?(value), do: Input.portable?(value) and safe_fields?(value)

  defp safe_fields?(value) when is_map(value),
    do:
      Enum.all?(value, fn {key, child} ->
        (is_atom(key) or is_binary(key) or is_number(key)) and
          to_string(key) not in @forbidden and safe_fields?(child)
      end)

  defp safe_fields?(value) when is_list(value), do: Enum.all?(value, &safe_fields?/1)

  defp safe_fields?(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.all?(&safe_fields?/1)

  defp safe_fields?(_), do: true

  defp body?(:message, body),
    do:
      keys?(body, [:route, :target, :name, :payload]) and
        body.route in [:self, :child, :parent, :root] and RootSchedule.identity?(body.target) and
        Schema.name?(body.name)

  defp body?(:timer_start, body),
    do:
      keys?(body, [:timer_id, :route, :target, :name, :payload, :delay, :interval]) and
        body?(:message, Map.take(body, [:route, :target, :name, :payload])) and
        Schema.name?(body.timer_id) and
        timeout?(body.delay) and (body.interval == nil or timeout?(body.interval))

  defp body?(:timer_cancel, body), do: keys?(body, [:timer_id]) and Schema.name?(body.timer_id)

  defp body?(:effect_request, body),
    do:
      request?(body, [:declaration, :payload, :timeout_ms, :idempotency_key, :fallback]) and
        body.fallback in [:deny, :omit, :component]

  defp body?(:command, body),
    do:
      request?(body, [
        :declaration,
        :payload,
        :timeout_ms,
        :idempotency_key,
        :optimistic_revision,
        :trust
      ]) and
        body.trust == :untrusted_client and
        (body.optimistic_revision == nil or positive?(body.optimistic_revision))

  defp body?(:effect_cancel, body),
    do: keys?(body, [:correlation]) and correlation?(body.correlation)

  defp body?(:resource_transfer, body),
    do:
      keys?(body, [:lease, :target]) and lease?(body.lease) and
        RootSchedule.identity?(body.target)

  defp body?(:resource_release, body), do: keys?(body, [:lease]) and lease?(body.lease)
  defp body?(_, _), do: false

  defp request?(body, keys),
    do:
      keys?(body, keys) and Schema.name?(body.declaration) and
        Schema.name?(body.idempotency_key) and timeout?(body.timeout_ms)

  defp timeout?(value), do: is_integer(value) and value in 10..60_000
end

defmodule BlazeX.Component.ActionPort do
  @moduledoc "Runtime-owned outward provider seam. Selection is read-only; submission is post-commit. No provider handles enter portable records."
  @callback select(term(), map()) :: :denied | {:granted, binary()} | {:fallback, binary()}
  @callback submit(term(), map()) :: :accepted | :denied | :disconnected | {:error, atom()}
  @callback cancel(term(), map()) :: :ok | {:error, atom()}
  @callback release(term(), map()) :: :released | :lost
  @callback prepare_release(term(), map()) ::
              {:ok, %{provider: binary(), token: term()}} | {:error, atom()}
  @callback release_ticket(term(), map()) :: :released | :lost | {:error, atom()}
  @callback release_ticket_page(term(), [map()]) ::
              [:released | :lost | {:error, atom()}]
  @optional_callbacks prepare_release: 2, release_ticket: 2, release_ticket_page: 2

  def valid?({module, _}) when is_atom(module),
    do:
      Code.ensure_loaded?(module) and
        Enum.all?([select: 2, submit: 2, cancel: 2, release: 2], fn {name, arity} ->
          function_exported?(module, name, arity)
        end)

  def valid?(_), do: false
end
