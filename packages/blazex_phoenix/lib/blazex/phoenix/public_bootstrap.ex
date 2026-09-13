defmodule BlazeX.Phoenix.PublicBootstrap do
  @moduledoc """
  Builds a bounded public bootstrap document from an attested static delivery.

  Bootstrap data is explicitly public and becomes untrusted client state after
  delivery. It never grants authentication, authorization, command, or server
  mutation authority.
  """

  alias BlazeX.Phoenix.StaticDelivery

  @max_depth 4
  @max_collection_items 32
  @max_nodes 256
  @max_key_bytes 64
  @max_string_bytes 256
  @max_document_bytes 4_096
  @max_safe_integer 9_007_199_254_740_991
  @key_pattern ~r/\A[a-z][a-z0-9_.-]{0,63}\z/
  @asset_base_pattern ~r{\A/(?:[a-z0-9][a-z0-9_-]*/)+\z}
  @forbidden_key ~r/(?:secret|token|password|passwd|credential|cookie|session|csrf|role|permission|authori[sz]ation|authentication|authenticated|identity|principal|user.?id|account.?id|allowed.?action|command|idempotency|private.?key)/i

  @enforce_keys [:document, :body, :bytes, :etag]
  defstruct [:document, :body, :bytes, :etag]

  @type t :: %__MODULE__{
          document: map(),
          body: binary(),
          bytes: non_neg_integer(),
          etag: String.t()
        }

  @spec build!(StaticDelivery.t(), map(), String.t()) :: t()
  def build!(%StaticDelivery{} = delivery, public_state \\ %{}, asset_base \\ "/bh07/") do
    validate_delivery!(delivery)
    asset_base = validate_asset_base!(asset_base)
    public_state = normalize_public_state!(public_state)
    manifest_digest = sha256(delivery.manifest_bytes)

    document = %{
      "asset_base" => asset_base,
      "attestation" => %{"id" => delivery.attestation["attestation_id"]},
      "capabilities" => %{
        "browser_local_execution" => true,
        "pushes" => false,
        "remote_commands" => false,
        "server_mutation" => false,
        "sessions" => false,
        "static_delivery" => true
      },
      "entrypoint" => delivery.manifest["entrypoint"],
      "manifest" => %{
        "id" => delivery.manifest["manifest_id"],
        "sha256" => manifest_digest,
        "url" => asset_base <> "build-manifest.json"
      },
      "protocol" => "blazex.bh07.bootstrap/1",
      "public_state" => public_state,
      "schema_version" => "1.0.0",
      "trust" => "public-untrusted-no-server-authority"
    }

    body = canonical_json(document) <> "\n"

    if byte_size(body) > @max_document_bytes do
      raise ArgumentError, "bootstrap-document-too-large"
    end

    %__MODULE__{
      document: document,
      body: body,
      bytes: byte_size(body),
      etag: ~s("sha256-#{sha256(body)}")
    }
  end

  defp validate_delivery!(delivery) do
    entrypoint = delivery.manifest["entrypoint"] || %{}
    expected_attestation_id = "blazex.bh06.entrypoint-accounting/1/#{entrypoint["id"]}"
    binding = delivery.attestation["manifest"] || %{}

    valid? =
      delivery.attestation["decision"] == "accept" and
        delivery.attestation["attestation_id"] == expected_attestation_id and
        delivery.attestation["entrypoint"] == entrypoint and
        binding["id"] == delivery.manifest["manifest_id"] and
        binding["sha256"] == sha256(delivery.manifest_bytes) and
        binding["support_state"] == delivery.manifest["support_state"]

    unless valid?, do: raise(ArgumentError, "bootstrap-delivery-identity-invalid")
  end

  defp validate_asset_base!(value) when is_binary(value) do
    cond do
      byte_size(value) > 128 ->
        raise ArgumentError, "bootstrap-asset-base-invalid"

      not Regex.match?(@asset_base_pattern, value) ->
        raise ArgumentError, "bootstrap-asset-base-invalid"

      true ->
        value
    end
  end

  defp validate_asset_base!(_value), do: raise(ArgumentError, "bootstrap-asset-base-invalid")

  defp normalize_public_state!(value) when is_map(value) do
    {normalized, _nodes} = normalize(value, 0, 0)
    normalized
  end

  defp normalize_public_state!(_value), do: raise(ArgumentError, "bootstrap-public-state-invalid")

  defp normalize(value, _depth, nodes) when is_nil(value) or is_boolean(value),
    do: {value, count_node!(nodes)}

  defp normalize(value, _depth, nodes)
       when is_integer(value) and value >= -@max_safe_integer and value <= @max_safe_integer,
       do: {value, count_node!(nodes)}

  defp normalize(value, _depth, nodes) when is_binary(value) do
    if not String.valid?(value) or byte_size(value) > @max_string_bytes do
      raise ArgumentError, "bootstrap-string-invalid"
    end

    {value, count_node!(nodes)}
  end

  defp normalize(value, depth, nodes) when is_list(value) do
    validate_collection!(value, depth, "bootstrap-list-invalid")

    {items, nodes} =
      Enum.map_reduce(value, count_node!(nodes), fn item, count ->
        normalize(item, depth + 1, count)
      end)

    {items, nodes}
  end

  defp normalize(value, depth, nodes) when is_map(value) do
    validate_collection!(Map.to_list(value), depth, "bootstrap-map-invalid")

    Enum.reduce(value, {%{}, count_node!(nodes)}, fn {key, item}, {result, count} ->
      validate_key!(key)
      {normalized, count} = normalize(item, depth + 1, count)
      {Map.put(result, key, normalized), count}
    end)
  end

  defp normalize(_value, _depth, _nodes),
    do: raise(ArgumentError, "bootstrap-value-invalid")

  defp count_node!(nodes) when nodes < @max_nodes, do: nodes + 1
  defp count_node!(_nodes), do: raise(ArgumentError, "bootstrap-node-limit-exceeded")

  defp validate_collection!(value, depth, error) do
    if depth >= @max_depth or length(value) > @max_collection_items do
      raise ArgumentError, error
    end
  end

  defp validate_key!(key) when is_binary(key) do
    if byte_size(key) > @max_key_bytes or not Regex.match?(@key_pattern, key) or
         Regex.match?(@forbidden_key, key) do
      raise ArgumentError, "bootstrap-key-invalid"
    end
  end

  defp validate_key!(_key), do: raise(ArgumentError, "bootstrap-key-invalid")

  defp sha256(bytes), do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

  defp canonical_json(value) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map_join(",", fn {key, item} -> canonical_json(key) <> ":" <> canonical_json(item) end)
    |> then(&("{" <> &1 <> "}"))
  end

  defp canonical_json(value) when is_list(value),
    do: "[" <> Enum.map_join(value, ",", &canonical_json/1) <> "]"

  defp canonical_json(value) when is_binary(value) do
    value
    |> String.to_charlist()
    |> Enum.map_join(&escape_codepoint/1)
    |> then(&("\"" <> &1 <> "\""))
  end

  defp canonical_json(value) when is_integer(value), do: Integer.to_string(value)
  defp canonical_json(true), do: "true"
  defp canonical_json(false), do: "false"
  defp canonical_json(nil), do: "null"

  defp escape_codepoint(?\"), do: "\\\""
  defp escape_codepoint(?\\), do: "\\\\"
  defp escape_codepoint(?\b), do: "\\b"
  defp escape_codepoint(?\f), do: "\\f"
  defp escape_codepoint(?\n), do: "\\n"
  defp escape_codepoint(?\r), do: "\\r"
  defp escape_codepoint(?\t), do: "\\t"

  defp escape_codepoint(codepoint) when codepoint < 0x20,
    do: "\\u" <> (codepoint |> Integer.to_string(16) |> String.pad_leading(4, "0"))

  defp escape_codepoint(codepoint), do: <<codepoint::utf8>>
end
