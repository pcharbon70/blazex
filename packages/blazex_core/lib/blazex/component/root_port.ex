defmodule BlazeX.Component.RootPort do
  @moduledoc """
  Versioned, renderer-neutral root lifecycle records. Private port configuration
  and candidate tokens are runtime-owned and must never enter callback inputs.
  Correlation is integrity checking inside a trusted runtime, not authentication.
  """
  alias BlazeX.Component.{Input, Invocation, NestedTable, Schema}

  @keys [
    :root,
    :instance,
    :owner,
    :component,
    :public_id,
    :props,
    :slots,
    :capabilities,
    :fallback,
    :timeout_ms
  ]
  @correlation [
    :root,
    :instance,
    :owner,
    :generation,
    :revision,
    :sequence,
    :operation,
    :transaction
  ]
  @failures [
    :invalid_start,
    :invalid_request,
    :busy,
    :stale,
    :semantic_rejected,
    :renderer_rejected,
    :rollback_failed,
    :timeout,
    :cleanup_failed,
    :port_failed,
    :crashed,
    :terminal
  ]

  def version, do: "0.1.0-bh05-root-lifecycle"
  def failures, do: @failures
  def failure(code), do: if(code in @failures, do: code, else: :port_failed)
  def handle(spec), do: Map.take(spec, [:root, :instance, :owner])

  def handle?(value),
    do: keys?(value, [:root, :instance, :owner]) and Enum.all?(Map.values(value), &Schema.name?/1)

  def normalize(spec) do
    with true <- keys?(spec, @keys),
         true <- handle?(handle(spec)) and Schema.name?(spec.public_id),
         true <- is_atom(spec.component) and Code.ensure_loaded?(spec.component),
         true <- function_exported?(spec.component, :__blazex_component__, 0),
         metadata <- spec.component.__blazex_component__(),
         true <- metadata.role == :root and metadata.version == Schema.version(),
         true <- Input.names?(spec.capabilities),
         true <- Enum.all?(metadata.declarations.capabilities, &(&1 in spec.capabilities)),
         true <- fallback?(spec.fallback),
         true <- is_integer(spec.timeout_ms) and spec.timeout_ms in 10..60_000,
         {:ok, invocation} <-
           Invocation.normalize(metadata.schema.declarations, spec.props, spec.slots, %{
             kind: :host,
             root: spec.root,
             owner: spec.root
           }),
         true <- Input.portable?(%{props: invocation.props, slots: Map.new(invocation.slots)}) do
      {:ok, %{spec | props: invocation.props, slots: Map.new(invocation.slots)}}
    else
      _ -> {:error, :invalid_start}
    end
  rescue
    _ -> {:error, :invalid_start}
  catch
    _, _ -> {:error, :invalid_start}
  end

  def ports?(ports) do
    keys?(ports, [:evaluator, :renderer, :host]) and
      port?(ports.evaluator, prepare: 3, cleanup: 3) and
      port?(ports.renderer, submit: 3, cancel: 2) and port?(ports.host, notify: 2)
  end

  def correlation(spec, generation, revision, sequence, operation) do
    value =
      Map.merge(handle(spec), %{
        generation: generation,
        revision: revision,
        sequence: sequence,
        operation: operation,
        transaction: spec.instance <> ":" <> Integer.to_string(sequence)
      })

    if correlation?(value), do: {:ok, value}, else: {:error, :invalid_request}
  end

  def correlation?(value) do
    keys?(value, @correlation) and handle?(handle(value)) and
      Enum.all?(
        [value.generation, value.revision, value.sequence],
        &(NestedTable.counter?(&1) and &1 > 0)
      ) and
      value.operation in [:mount, :update, :replace, :dispose, :failure] and
      value.transaction == value.instance <> ":" <> Integer.to_string(value.sequence)
  end

  def candidate(correlation, state, output_digest, token) do
    if correlation?(correlation) and Input.portable?(state) and hash?(output_digest) do
      {:ok,
       %{
         correlation: correlation,
         state: state,
         state_digest: NestedTable.digest(state),
         output_digest: output_digest,
         final_digest: NestedTable.digest({correlation, state, output_digest}),
         token: token
       }}
    else
      {:error, :semantic_rejected}
    end
  end

  def candidate?(value, correlation) do
    keys?(value, [:correlation, :state, :state_digest, :output_digest, :final_digest, :token]) and
      value.correlation == correlation and
      candidate(correlation, value.state, value.output_digest, value.token) == {:ok, value}
  end

  def acknowledgement?(value, expected) do
    keys?(value, [:correlation, :result]) and value.correlation == expected and
      correlation?(expected) and value.result in [:committed, :rejected, :rolled_back]
  end

  def summary(nil), do: nil

  def summary(value),
    do: Map.take(value, [:correlation, :state_digest, :output_digest, :final_digest])

  def call({module, config}, callback, arguments) do
    apply(module, callback, [config | arguments])
  rescue
    _ -> {:error, :port_failed}
  catch
    _, _ -> {:error, :port_failed}
  end

  def call_page([{{module, config} = port, :release, [_]} | _] = calls) do
    if function_exported?(module, :release_page, 2) and
         Enum.all?(calls, fn {candidate, callback, arguments} ->
           candidate == port and callback == :release and length(arguments) == 1
         end) do
      leases = Enum.map(calls, fn {_, _, [lease]} -> lease end)

      case apply(module, :release_page, [config, leases]) do
        results when is_list(results) and length(results) == length(calls) -> results
        _ -> List.duplicate({:error, :port_failed}, length(calls))
      end
    else
      Enum.map(calls, fn {candidate, callback, arguments} ->
        call(candidate, callback, arguments)
      end)
    end
  rescue
    _ -> List.duplicate({:error, :port_failed}, length(calls))
  catch
    _, _ -> List.duplicate({:error, :port_failed}, length(calls))
  end

  def call_page(calls) when is_list(calls),
    do: Enum.map(calls, fn {port, callback, arguments} -> call(port, callback, arguments) end)

  def release_page({module, config} = port, leases)
      when is_list(leases) and length(leases) <= 128 do
    requested = Enum.map(leases, &Map.put(&1, :release_requested, true))

    if function_exported?(module, :release_page, 2) do
      case apply(module, :release_page, [config, requested]) do
        results when is_list(results) and length(results) == length(leases) -> results
        _ -> List.duplicate({:error, :port_failed}, length(leases))
      end
    else
      Enum.map(requested, &call(port, :release, [&1]))
    end
  rescue
    _ -> List.duplicate({:error, :port_failed}, length(leases))
  catch
    _, _ -> List.duplicate({:error, :port_failed}, length(leases))
  end

  def release_prepared_page({module, config} = port, leases)
      when is_list(leases) and leases != [] and length(leases) <= 64 do
    true = Enum.all?(leases, &(is_map(&1) and Map.get(&1, :release_requested) == true))

    if function_exported?(module, :release_page, 2) do
      case module.release_page(config, leases) do
        results when is_list(results) and length(results) == length(leases) -> results
        _ -> List.duplicate({:error, :port_failed}, length(leases))
      end
    else
      Enum.map(leases, &call(port, :release, [&1]))
    end
  rescue
    _ -> List.duplicate({:error, :port_failed}, length(leases))
  catch
    _, _ -> List.duplicate({:error, :port_failed}, length(leases))
  end

  defp keys?(value, keys),
    do: is_map(value) and not is_struct(value) and Enum.sort(Map.keys(value)) == Enum.sort(keys)

  defp fallback?(:none), do: true
  defp fallback?({:static, id}), do: Schema.name?(id)
  defp fallback?(_), do: false

  defp hash?(value),
    do: is_binary(value) and byte_size(value) == 64 and lowercase_hex?(value)

  defp lowercase_hex?(<<>>), do: true

  defp lowercase_hex?(<<byte, rest::binary>>) when byte in ?0..?9 or byte in ?a..?f,
    do: lowercase_hex?(rest)

  defp lowercase_hex?(_), do: false

  defp port?({module, _config}, callbacks) when is_atom(module),
    do:
      Code.ensure_loaded?(module) and
        Enum.all?(callbacks, fn {name, arity} -> function_exported?(module, name, arity) end)

  defp port?(_, _), do: false
end

defmodule BlazeX.Component.RootPort.Evaluator do
  @moduledoc "Trusted outward evaluator; requests contain spec, operation and correlation. Cleanup consumes an old private candidate after renderer disposal/replace."
  @callback prepare(term(), map(), map() | nil) :: {:ok, map()} | {:error, atom()}
  @callback cleanup(term(), map(), :replace | :shutdown | :removal) :: :ok | {:error, atom()}
end

defmodule BlazeX.Component.RootPort.Renderer do
  @moduledoc "Trusted outward transaction port. :ok means submitted, never committed. Cancellation must confirm rollback before returning :ok."
  @callback submit(term(), map(), map() | nil) :: :ok | {:error, atom()}
  @callback cancel(term(), map()) :: :ok | {:error, atom()}
end

defmodule BlazeX.Component.RootPort.Host do
  @moduledoc "Receives bounded identity/counter/digest lifecycle observations, never callback state or private adapter tokens."
  @callback notify(term(), map()) :: :ok | {:error, atom()}
end
