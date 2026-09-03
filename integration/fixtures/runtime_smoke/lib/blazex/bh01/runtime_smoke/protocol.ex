defmodule BlazeX.BH01.RuntimeSmoke.Protocol do
  @moduledoc false

  @version 1
  @max_depth 4
  @max_collection 16
  @max_binary_bytes 256
  @max_payload_units 1_024
  @allowed_tags ["echo", "cancel"]
  @forbidden_keys ["code", "dom_handle", "filesystem_path", "secret"]

  def new_state(generation \\ 1) do
    %{
      generation: generation,
      seen_request_ids: [],
      settled_request_ids: [],
      cancelled_request_ids: [],
      disposed: false
    }
  end

  def accept(_envelope, %{disposed: true} = state), do: {:error, :disposed, state}

  def accept(envelope, state) when is_map(envelope) do
    with :ok <- exact_keys(envelope),
         :ok <- field(envelope, "version", @version),
         {:ok, request_id} <- positive_integer(envelope, "request_id"),
         {:ok, generation} <- positive_integer(envelope, "generation"),
         :ok <- current_generation(generation, state),
         :ok <- unseen_request(request_id, state),
         {:ok, tag} <- allowed_tag(envelope),
         {:ok, payload} <- payload(envelope) do
      next_state = %{state | seen_request_ids: [request_id | state.seen_request_ids]}

      response = %{
        "version" => @version,
        "request_id" => request_id,
        "generation" => generation,
        "tag" => tag,
        "payload" => payload,
        "status" => "ok"
      }

      {:ok, response, next_state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  def accept(_envelope, state), do: {:error, :malformed_envelope, state}

  def cancel(request_id, state) when is_integer(request_id) and request_id > 0 do
    %{state | cancelled_request_ids: [request_id | state.cancelled_request_ids]}
  end

  def dispose(state), do: %{state | disposed: true}

  def settle_reply(_request_id, _generation, %{disposed: true} = state),
    do: {:error, :disposed, state}

  def settle_reply(request_id, generation, state) do
    cond do
      generation != state.generation ->
        {:error, :stale_generation, state}

      request_id in state.cancelled_request_ids ->
        {:error, :cancelled_request, state}

      request_id not in state.seen_request_ids ->
        {:error, :unknown_request, state}

      request_id in state.settled_request_ids ->
        {:error, :duplicate_reply, state}

      true ->
        {:ok, %{state | settled_request_ids: [request_id | state.settled_request_ids]}}
    end
  end

  def classify_failure({:host_error, reason}), do: {:error, :host, reason}
  def classify_failure({:runtime_error, reason}), do: {:error, :runtime, reason}
  def classify_failure(_other), do: {:error, :malformed_failure}

  defp exact_keys(envelope) do
    expected = ["generation", "payload", "request_id", "tag", "version"]
    if Enum.sort(Map.keys(envelope)) == expected, do: :ok, else: {:error, :schema_mismatch}
  end

  defp field(envelope, key, expected) do
    if Map.get(envelope, key) == expected, do: :ok, else: {:error, :version_mismatch}
  end

  defp positive_integer(envelope, key) do
    case Map.get(envelope, key) do
      value when is_integer(value) and value > 0 -> {:ok, value}
      _ -> {:error, :invalid_identity}
    end
  end

  defp current_generation(generation, %{generation: generation}), do: :ok
  defp current_generation(_generation, _state), do: {:error, :stale_generation}

  defp unseen_request(request_id, state) do
    if request_id in state.seen_request_ids, do: {:error, :duplicate_request}, else: :ok
  end

  defp allowed_tag(envelope) do
    case Map.get(envelope, "tag") do
      tag when tag in @allowed_tags -> {:ok, tag}
      _ -> {:error, :unknown_tag}
    end
  end

  defp payload(envelope) do
    value = Map.get(envelope, "payload")

    with {:ok, units} <- payload_units(value, 0),
         true <- units <= @max_payload_units do
      {:ok, value}
    else
      false -> {:error, :payload_too_large}
      {:error, reason} -> {:error, reason}
    end
  end

  defp payload_units(_value, depth) when depth > @max_depth, do: {:error, :payload_too_deep}
  defp payload_units(nil, _depth), do: {:ok, 1}

  defp payload_units(value, _depth)
       when is_boolean(value) or is_integer(value) or is_float(value),
       do: {:ok, 1}

  defp payload_units(value, _depth) when is_binary(value) do
    cond do
      byte_size(value) > @max_binary_bytes -> {:error, :binary_too_large}
      String.starts_with?(value, "/") -> {:error, :filesystem_path_rejected}
      true -> {:ok, byte_size(value)}
    end
  end

  defp payload_units(value, depth) when is_list(value) and length(value) <= @max_collection do
    sum_units(value, depth + 1, 1)
  end

  defp payload_units(value, depth) when is_map(value) and map_size(value) <= @max_collection do
    if Enum.all?(Map.keys(value), &(is_binary(&1) and &1 not in @forbidden_keys)) do
      value
      |> Map.to_list()
      |> Enum.map(fn {key, item} -> [key, item] end)
      |> List.flatten()
      |> sum_units(depth + 1, 1)
    else
      {:error, :forbidden_or_non_string_key}
    end
  end

  defp payload_units(_value, _depth), do: {:error, :unsupported_payload}

  defp sum_units([], _depth, total), do: {:ok, total}

  defp sum_units([value | rest], depth, total) do
    case payload_units(value, depth) do
      {:ok, units} when total + units <= @max_payload_units ->
        sum_units(rest, depth, total + units)

      {:ok, _units} ->
        {:error, :payload_too_large}

      error ->
        error
    end
  end
end
