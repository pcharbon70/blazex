defmodule BlazeX.BH01.BrowserHost.Protocol do
  @moduledoc false

  @protocol "blazex.host-bridge/1"
  @operations [
    "runtime.echo",
    "runtime.shutdown",
    "root.register",
    "root.mount",
    "root.update",
    "root.move",
    "root.dispose",
    "fixture.command",
    "fixture.event",
    "fixture.snapshot"
  ]
  @max_depth 6
  @max_items 64
  @max_string_bytes 2_048
  @sensitive ["authorization", "cookie", "credential", "password", "secret", "token"]
  @roots_key :blazex_bh03_profile_roots

  def handle(
        %{
          "protocol" => @protocol,
          "type" => "request",
          "scenario_id" => scenario,
          "generation" => generation,
          "correlation_id" => correlation,
          "sequence" => sequence,
          "operation" => operation,
          "payload" => payload,
          "timeout_ms" => timeout,
          "retry" => 0
        } = request
      )
      when is_binary(scenario) and byte_size(scenario) <= 96 and is_integer(generation) and
             generation > 0 and
             is_binary(correlation) and byte_size(correlation) <= 96 and
             is_integer(sequence) and sequence > 0 and operation in @operations and
             is_integer(timeout) and timeout > 0 and timeout <= 10_000 do
    with {:ok, _items} <- bounded(payload, 0, 0),
         true <- byte_size(Jason.encode!(request)) <= 8_192 do
      execute(request, operation, payload)
    else
      _ ->
        {:error,
         response(request, "error", %{
           "error" =>
             error("bridge-payload-invalid", "The request payload is outside the governed bounds")
         })}
    end
  end

  def handle(request) when is_map(request) do
    {:error,
     response(request, "error", %{
       "error" =>
         error("bridge-request-invalid", "The request envelope is malformed or forbidden")
     })}
  end

  def handle(_), do: {:error, fallback_error()}

  defp execute(request, "runtime.echo", payload),
    do: {:ok, response(request, "ok", %{"result" => payload}), "runtime.echo"}

  defp execute(
         request,
         "runtime.shutdown",
         %{"scope_id" => scope_id, "runtime_generation" => runtime_generation}
       )
       when is_binary(scope_id) and is_integer(runtime_generation) and runtime_generation > 0 do
    Process.delete(@roots_key)

    {:ok,
     response(request, "ok", %{
       "result" => %{
         "scope_id" => scope_id,
         "runtime_generation" => runtime_generation,
         "runtime_fixture" => "bh03-profile"
       }
     }), "runtime.shutdown"}
  end

  defp execute(request, operation, payload)
       when operation in [
              "root.register",
              "root.mount",
              "root.update",
              "root.move",
              "root.dispose"
            ],
       do: root_operation(request, operation, payload)

  defp execute(request, "fixture.snapshot", _payload),
    do:
      {:ok,
       response(request, "ok", %{
         "result" => BlazeX.BH01.LocalBehavior.snapshot(Map.fetch!(request, "generation"))
       }), "fixture.snapshot"}

  defp execute(request, "fixture.command", payload),
    do:
      fixture_result(
        request,
        BlazeX.BH01.LocalBehavior.command(Map.fetch!(request, "generation"), payload),
        "fixture.command"
      )

  defp execute(request, "fixture.event", payload),
    do:
      fixture_result(
        request,
        BlazeX.BH01.LocalBehavior.event(Map.fetch!(request, "generation"), payload),
        "fixture.event"
      )

  defp execute(request, _operation, _payload),
    do:
      {:error,
       response(request, "error", %{
         "error" =>
           error("bridge-operation-payload-invalid", "The operation payload is malformed")
       })}

  defp root_operation(
         request,
         operation,
         %{"root_id" => root_id, "root_generation" => root_generation} = payload
       )
       when is_binary(root_id) and byte_size(root_id) <= 64 and is_integer(root_generation) and
              root_generation > 0 do
    roots = Process.get(@roots_key, %{})
    current = Map.get(roots, root_id)

    with {:ok, next} <- root_transition(operation, current, payload) do
      Process.put(@roots_key, Map.put(roots, root_id, next))

      {:ok,
       response(request, "ok", %{
         "result" => %{
           "root_id" => root_id,
           "root_generation" => root_generation,
           "runtime_fixture" => "bh03-profile"
         }
       }), operation}
    else
      {:error, code, message} ->
        {:error, response(request, "error", %{"error" => error(code, message)})}
    end
  end

  defp root_operation(request, _operation, _payload),
    do:
      {:error,
       response(request, "error", %{
         "error" => error("root-payload-invalid", "The root operation payload is malformed")
       })}

  defp root_transition("root.register", nil, %{"root_generation" => generation}),
    do: {:ok, %{state: :registered, generation: generation}}

  defp root_transition("root.register", _current, _payload),
    do: {:error, "root-duplicate", "The root is already registered"}

  defp root_transition(
         "root.mount",
         %{state: state},
         %{"root_generation" => generation, "target_id" => target_id, "tree" => tree}
       )
       when state in [:registered, :disposed] and is_binary(target_id) and
              byte_size(target_id) <= 64,
       do: {:ok, %{state: :ready, generation: generation, target_id: target_id, tree: tree}}

  defp root_transition(
         "root.update",
         %{state: :ready} = current,
         %{"root_generation" => generation, "tree" => tree}
       ),
       do: {:ok, %{current | generation: generation, tree: tree}}

  defp root_transition(
         "root.move",
         %{state: :ready} = current,
         %{"root_generation" => generation, "target_id" => target_id}
       )
       when is_binary(target_id) and byte_size(target_id) <= 64,
       do: {:ok, %{current | generation: generation, target_id: target_id}}

  defp root_transition(
         "root.dispose",
         %{state: state},
         %{"root_generation" => generation}
       )
       when state in [:registered, :ready],
       do: {:ok, %{state: :disposed, generation: generation}}

  defp root_transition(_operation, _current, _payload),
    do: {:error, "root-transition-invalid", "The root operation is invalid in its current state"}

  defp fixture_result(request, {:ok, effect, result}, operation) do
    :ok = Popcorn.Wasm.send_event("bh01_fixture_effect", effect)
    {:ok, response(request, "ok", %{"result" => result}), operation}
  end

  defp fixture_result(request, {:error, error}, _operation),
    do: {:error, response(request, "error", %{"error" => error})}

  defp response(request, status, content) do
    Map.merge(
      %{
        "protocol" => @protocol,
        "type" => "response",
        "scenario_id" => Map.get(request, "scenario_id", "invalid"),
        "generation" => Map.get(request, "generation", 1),
        "correlation_id" => Map.get(request, "correlation_id", "invalid"),
        "sequence" => Map.get(request, "sequence", 1),
        "status" => status
      },
      content
    )
  end

  defp fallback_error do
    response(%{}, "error", %{
      "error" => error("bridge-request-invalid", "The request envelope is malformed or forbidden")
    })
  end

  defp error(code, message), do: %{"code" => code, "message" => message}

  defp bounded(value, _depth, items) when is_nil(value) or is_boolean(value), do: count(items)
  defp bounded(value, _depth, items) when is_integer(value), do: count(items)
  defp bounded(value, _depth, items) when is_float(value), do: count(items)

  defp bounded(value, _depth, items)
       when is_binary(value) and byte_size(value) <= @max_string_bytes,
       do: count(items)

  defp bounded(value, depth, items) when is_list(value) and depth < @max_depth do
    Enum.reduce_while(value, count(items + length(value)), fn
      item, {:ok, total} ->
        case bounded(item, depth + 1, total) do
          {:ok, next} -> {:cont, {:ok, next}}
          :error -> {:halt, :error}
        end

      _, :error ->
        {:halt, :error}
    end)
  end

  defp bounded(value, depth, items) when is_map(value) and depth < @max_depth do
    Enum.reduce_while(value, count(items + map_size(value)), fn
      {key, item}, {:ok, total} when is_binary(key) and byte_size(key) <= 96 ->
        if allowed_key?(key) do
          case bounded(item, depth + 1, total) do
            {:ok, next} -> {:cont, {:ok, next}}
            :error -> {:halt, :error}
          end
        else
          {:halt, :error}
        end

      _, _ ->
        {:halt, :error}
    end)
  end

  defp bounded(_, _, _), do: :error
  defp count(items) when items <= @max_items, do: {:ok, items}
  defp count(_), do: :error

  defp allowed_key?(key) do
    lower = String.downcase(key)
    not Enum.any?(@sensitive, &String.contains?(lower, &1))
  end
end
