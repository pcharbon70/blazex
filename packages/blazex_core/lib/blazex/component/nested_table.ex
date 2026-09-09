defmodule BlazeX.Component.NestedTable do
  @moduledoc """
  Immutable root-owned accepted nested records. Contains no process or renderer.
  Digests are deterministic ERTS integrity observations, not authentication.
  """
  alias BlazeX.Component.{Input, Schema}
  alias BlazeX.Core.Identity
  @max 9_007_199_254_740_991
  @keys [
    :identity,
    :parent,
    :module,
    :public_id,
    :role,
    :contract,
    :schema_digest,
    :invocation,
    :invocation_digest,
    :state,
    :output_digest,
    :generation,
    :revision,
    :sequence,
    :status,
    :owned_actions
  ]
  @enforce_keys [:root, :revision, :sequence, :records, :digest]
  defstruct @enforce_keys

  def new(root, revision, sequence, records) do
    if valid_parts?(root, revision, sequence, records) do
      {:ok,
       %__MODULE__{
         root: root,
         revision: revision,
         sequence: sequence,
         records: records,
         digest: digest({root, revision, sequence, records})
       }}
    else
      {:error, :invalid_nested_table}
    end
  rescue
    _ -> {:error, :invalid_nested_table}
  end

  def valid?(%__MODULE__{} = table),
    do: new(table.root, table.revision, table.sequence, table.records) == {:ok, table}

  def valid?(_), do: false
  def index(%__MODULE__{records: records}), do: Map.new(records, &{&1.identity, &1})
  def counter?(value), do: is_integer(value) and value in 0..@max

  def digest(value),
    do:
      :crypto.hash(:sha256, :erlang.term_to_binary(value, [:deterministic]))
      |> Base.encode16(case: :lower)

  defp valid_parts?(root, revision, sequence, records) do
    Identity.valid?(root) and root.path == [] and root.generation <= @max and
      counter?(revision) and revision > 0 and counter?(sequence) and
      Schema.list?(records, 256) and records != [] and
      hd(records).identity == root and
      Enum.all?(records, &valid_record?(&1, root, revision, sequence)) and
      length(Enum.uniq_by(records, & &1.identity)) == length(records) and
      Enum.all?(records, fn record ->
        record.parent == nil or Enum.any?(records, &(&1.identity == record.parent))
      end)
  end

  defp valid_record?(record, root, revision, sequence) do
    is_map(record) and Enum.sort(Map.keys(record)) == Enum.sort(@keys) and
      Identity.valid?(record.identity) and Identity.contains?(root, record.identity) and
      length(record.identity.path) <= 12 and record.generation == root.generation and
      record.revision == revision and record.sequence == sequence and record.status == :accepted and
      record.owned_actions == [] and Schema.name?(record.public_id) and
      record.contract == "0.1.0-bh05-nested-state" and hash?(record.schema_digest) and
      is_map(record.invocation) and Enum.sort(Map.keys(record.invocation)) == [:props, :slots] and
      Input.portable?(record.invocation) and record.invocation_digest == digest(record.invocation) and
      hash?(record.output_digest) and state?(record) and parent?(record, root)
  end

  defp parent?(%{identity: root, parent: nil, role: :pure}, root), do: true

  defp parent?(record, root) do
    parent = record.parent

    Identity.valid?(parent) and Identity.contains?(root, parent) and
      record.identity.path != [] and Enum.drop(record.identity.path, -1) == parent.path
  end

  defp state?(%{role: :pure, state: :absent, module: module}), do: is_atom(module)

  defp state?(%{role: :stateful, state: {:present, value}, module: module}),
    do: is_atom(module) and module != nil and Input.portable?(value)

  defp state?(_), do: false

  defp hash?(value),
    do: is_binary(value) and byte_size(value) == 64 and String.match?(value, ~r/\A[0-9a-f]+\z/)
end
