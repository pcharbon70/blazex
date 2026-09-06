defmodule BlazeX.Host.Browser.Compatibility do
  @moduledoc """
  Fail-closed compatibility negotiation for the experimental browser host.

  Identities are opaque and exact. Unknown, missing, repeated, malformed, or
  mismatched entries are rejected before any artifact can be acquired.
  """

  @required %{
    "browser_host" => "blazex.browser-host/1",
    "runtime_adapter" => "blazex.popcorn-runtime-adapter/1",
    "runtime_loader" => "blazex.browser-runtime-loader/1",
    "profile_manifest" => "blazex.browser-profile-manifest/1",
    "root_lifecycle" => "blazex.browser-root-lifecycle/1",
    "semantic_tree" => "blazex.ui-tree/1",
    "renderer" => "blazex.renderer/1",
    "dom_projection" => "blazex.dom-projection/1"
  }

  @identity_pattern ~r/^blazex\.[a-z0-9-]+\/[1-9][0-9]*$/

  @doc "Returns the complete exact-match identity table."
  @spec required_identities() :: map()
  def required_identities, do: @required

  @doc "Returns a normalized compatible result or a deterministic mismatch."
  @spec negotiate(map() | [{String.t(), String.t()}]) :: {:ok, map()} | {:error, map()}
  def negotiate(observed) do
    with {:ok, entries} <- entries(observed),
         :ok <- reject_malformed(entries),
         :ok <- reject_duplicates(entries),
         observed_map = Map.new(entries),
         :ok <- reject_missing(observed_map),
         :ok <- reject_unknown(observed_map),
         :ok <- reject_mismatches(observed_map) do
      {:ok,
       %{
         protocol: "blazex.compatibility-negotiation/1",
         decision: :compatible,
         identities: @required
       }}
    end
  end

  defp entries(value) when is_map(value), do: {:ok, Map.to_list(value)}
  defp entries(value) when is_list(value), do: {:ok, value}
  defp entries(_value), do: mismatch(:malformed, %{expected: "map-or-key-value-list"})

  defp reject_malformed(entries) do
    if Enum.all?(entries, fn
         {key, identity} when is_binary(key) and is_binary(identity) ->
           Regex.match?(~r/^[a-z][a-z0-9_]*$/, key) and Regex.match?(@identity_pattern, identity)

         _other ->
           false
       end) do
      :ok
    else
      mismatch(:malformed, %{})
    end
  end

  defp reject_duplicates(entries) do
    duplicates =
      entries
      |> Enum.map(&elem(&1, 0))
      |> Enum.frequencies()
      |> Enum.filter(fn {_key, count} -> count > 1 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    if duplicates == [], do: :ok, else: mismatch(:duplicate, %{keys: duplicates})
  end

  defp reject_missing(observed) do
    missing = @required |> Map.keys() |> Kernel.--(Map.keys(observed)) |> Enum.sort()
    if missing == [], do: :ok, else: mismatch(:missing, %{keys: missing})
  end

  defp reject_unknown(observed) do
    unknown = observed |> Map.keys() |> Kernel.--(Map.keys(@required)) |> Enum.sort()
    if unknown == [], do: :ok, else: mismatch(:unknown, %{keys: unknown})
  end

  defp reject_mismatches(observed) do
    mismatches =
      @required
      |> Enum.filter(fn {key, expected} -> Map.get(observed, key) != expected end)
      |> Enum.map(fn {key, expected} ->
        %{key: key, expected: expected, observed: Map.get(observed, key)}
      end)
      |> Enum.sort_by(& &1.key)

    if mismatches == [], do: :ok, else: mismatch(:mismatch, %{identities: mismatches})
  end

  defp mismatch(reason, details) do
    {:error,
     %{
       class: :identity_mismatch,
       reason: reason,
       phase: :before_artifact_acquisition,
       details: details
     }}
  end
end
