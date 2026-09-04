defmodule BlazeX.Renderer.DOM.LiveView do
  @moduledoc """
  Experimental BH-01 boundary for optional version-sensitive renderer data.

  This disposable compatibility adapter consumes only an explicit descriptor
  and fixture patch envelope. It does not make LiveView internals portable or
  stable. A mismatch disables this path before any patch is applied.
  """

  alias BlazeX.Renderer.DOM.LiveView.Compatibility

  @patch_protocol "blazex.bh01.liveview-patch/0.1"

  def capability(descriptor, enabled \\ true)

  def capability(_descriptor, false),
    do: disabled("disabled-by-configuration")

  def capability(descriptor, true) do
    case Compatibility.probe(descriptor) do
      {:ok, report} ->
        %{
          "protocol" => "blazex.bh01.liveview-capability/0.1",
          "status" => "eligible",
          "adapter" => Compatibility.adapter_id(),
          "versions" => report["versions"],
          "fallback" => "standalone-dom"
        }

      {:error, report} ->
        disabled(report["reason"])
    end
  end

  def activate(descriptor, options \\ []) do
    enabled = Keyword.get(options, :enabled, true)

    case capability(descriptor, enabled) do
      %{"status" => "eligible"} = capability ->
        {:ok,
         %{
           protocol: "blazex.bh01.liveview-adapter-state/0.1",
           status: :active,
           generation: 1,
           last_sequence: 0,
           connected: true,
           stale_drops: 0,
           applied: 0,
           capability: capability
         }}

      report ->
        {:disabled, report}
    end
  end

  def apply_patch(%{status: status} = state, patch) when status in [:active, :awaiting_full] do
    with {:ok, normalized} <- validate_patch(patch),
         :ok <- validate_generation(normalized, state),
         :ok <- validate_order(normalized, state),
         :ok <- validate_kind(normalized, state) do
      next = %{
        state
        | status: :active,
          last_sequence: normalized.sequence,
          applied: state.applied + 1
      }

      {:ok,
       %{
         "protocol" => "blazex.bh01.liveview-translation/0.1",
         "generation" => normalized.generation,
         "sequence" => normalized.sequence,
         "kind" => normalized.kind,
         "payload" => normalized.payload
       }, next}
    else
      {:drop, reason} ->
        next = %{state | stale_drops: state.stale_drops + 1}
        {:drop, %{"reason" => reason}, next}

      {:disable, reason} ->
        next = %{state | status: :disabled, connected: false}
        {:disabled, disabled(reason), next}

      {:error, reason} ->
        next = %{state | status: :disabled, connected: false}
        {:disabled, disabled(reason), next}
    end
  end

  def apply_patch(state, _patch),
    do: {:disabled, disabled("adapter-not-active"), state}

  def disconnect(%{status: status} = state) when status in [:active, :awaiting_full],
    do: %{state | status: :disconnected, connected: false}

  def disconnect(state), do: state

  def reconnect(%{status: :disconnected} = state),
    do: %{state | status: :awaiting_full, connected: true}

  def reconnect(state), do: state

  def dispose(state),
    do: %{state | status: :disposed, connected: false}

  def snapshot(state) do
    %{
      "protocol" => state.protocol,
      "status" => Atom.to_string(state.status),
      "generation" => state.generation,
      "last_sequence" => state.last_sequence,
      "connected" => state.connected,
      "stale_drops" => state.stale_drops,
      "applied" => state.applied
    }
  end

  defp validate_patch(
         %{
           "protocol" => @patch_protocol,
           "generation" => generation,
           "sequence" => sequence,
           "kind" => kind,
           "payload" => payload
         } = patch
       )
       when is_integer(generation) and generation > 0 and is_integer(sequence) and sequence > 0 and
              kind in ["full", "diff"] and is_map(payload) and map_size(payload) <= 32 do
    if Enum.sort(Map.keys(patch)) == ~w(generation kind payload protocol sequence) and
         bounded?(payload, 0, 0) do
      {:ok, %{generation: generation, sequence: sequence, kind: kind, payload: payload}}
    else
      {:error, "patch-shape-invalid"}
    end
  end

  defp validate_patch(_patch), do: {:error, "patch-envelope-invalid"}

  defp validate_generation(%{generation: generation}, %{generation: generation}), do: :ok
  defp validate_generation(_patch, _state), do: {:drop, "patch-generation-stale"}

  defp validate_order(%{sequence: sequence}, %{last_sequence: last}) when sequence > last, do: :ok
  defp validate_order(_patch, _state), do: {:drop, "patch-sequence-stale"}

  defp validate_kind(%{kind: "full"}, %{status: :awaiting_full}), do: :ok

  defp validate_kind(%{kind: "diff"}, %{status: :awaiting_full}),
    do: {:drop, "full-patch-required"}

  defp validate_kind(_patch, _state), do: :ok

  defp bounded?(_value, depth, _items) when depth > 4, do: false
  defp bounded?(value, _depth, items) when is_nil(value) or is_boolean(value), do: items <= 64
  defp bounded?(value, _depth, items) when is_number(value), do: items <= 64

  defp bounded?(value, _depth, items) when is_binary(value),
    do: items <= 64 and byte_size(value) <= 2_048

  defp bounded?(value, depth, items) when is_list(value) and items + length(value) <= 64,
    do: Enum.all?(value, &bounded?(&1, depth + 1, items + length(value)))

  defp bounded?(value, depth, items) when is_map(value) and items + map_size(value) <= 64 do
    Enum.all?(value, fn {key, item} ->
      is_binary(key) and byte_size(key) <= 64 and
        bounded?(item, depth + 1, items + map_size(value))
    end)
  end

  defp bounded?(_value, _depth, _items), do: false

  defp disabled(reason) do
    %{
      "protocol" => "blazex.bh01.liveview-capability/0.1",
      "status" => "disabled",
      "adapter" => Compatibility.adapter_id(),
      "reason" => reason,
      "fallback" => "standalone-dom"
    }
  end
end
