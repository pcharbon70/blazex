defmodule BlazeX.BH01.BrowserHost.Protocol do
  @moduledoc false

  @protocol "blazex.host-bridge/1"
  @operations ["runtime.echo", "runtime.shutdown"]
  @max_depth 6
  @max_items 64
  @max_string_bytes 2_048
  @sensitive ["authorization", "cookie", "credential", "password", "secret", "token"]

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
      result = if operation == "runtime.echo", do: payload, else: %{"accepted" => true}
      {:ok, response(request, "ok", %{"result" => result}), operation}
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
