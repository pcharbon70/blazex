defmodule BlazeX.Component.ActionLedger do
  @moduledoc false
  alias BlazeX.Component.{Action, ActionManifest, RootPort, RootSchedule, Schema}
  defstruct pending: %{}, leases: %{}, sequences: %{}, history: [], totals: %{}

  def prepare(ledger, groups, candidate, spec, manifest, port) do
    true = is_list(groups) and length(groups) <= 128 and Action.size?(groups, 65_536)

    actions =
      Enum.flat_map(groups, fn group ->
        true = Action.keys?(group, [:source, :actions]) and is_list(group.actions)
        true = Enum.all?(group.actions, &(Action.valid?(&1) and &1.owner == group.source))
        group.actions
      end)

    true = length(actions) <= 16
    true = actions |> Enum.map(&{&1.owner, &1.id}) |> Enum.uniq() |> length() == length(actions)

    {actions, sequences} =
      Enum.map_reduce(actions, ledger.sequences, fn action, sequences ->
        component = RootSchedule.component(candidate, action.owner)
        true = component != nil and component.role in [:root, :stateful]
        true = action.owner.generation == candidate.correlation.generation
        true = action.sequence > Map.get(sequences, action.owner, 0)
        true = Map.has_key?(manifest.owners, component.public_id)

        action =
          if action.kind in [:effect_request, :command] do
            {:ok, declaration, normalized} =
              ActionManifest.declaration(manifest, action, component, spec)

            request = %{
              correlation: Action.correlation(action, spec),
              action: normalized,
              declaration: declaration,
              source_stamp: component.schema_digest,
              selection: select(port, action, declaration),
              status: :accepted
            }

            true =
              not Enum.any?(ledger.pending, fn {_, entry} ->
                entry.action.owner == action.owner and entry.action.id == action.id
              end)

            Map.put(normalized, :request, request)
          else
            validate_control!(ledger, action)
            action
          end

        {action, Map.put(sequences, action.owner, action.sequence)}
      end)

    requests = Enum.filter(actions, &(&1.kind in [:effect_request, :command]))
    true = map_size(sequences) <= 128 and map_size(ledger.pending) + length(requests) <= 128

    true =
      lease_depth(ledger) +
        Enum.sum(Enum.map(requests, &Map.get(&1.request.declaration, :lease_limit, 0))) <= 512

    {:ok, %{actions: actions, sequences: sequences, requests: length(requests)}}
  rescue
    _ -> {:error, :invalid_action_batch}
  catch
    _, _ -> {:error, :invalid_action_batch}
  end

  def install(ledger, request),
    do:
      record(
        %{ledger | pending: Map.put(ledger.pending, request.correlation, request)},
        :accepted,
        request.correlation
      )

  def complete(ledger, result, accepted) do
    with true <- Action.result?(result) and result.status not in [:accepted, :stale],
         entry when is_map(entry) <- Map.get(ledger.pending, result.correlation),
         true <- live?(entry, accepted),
         :ok <- result_value(entry, result),
         true <- result.leases == [] do
      next = %{ledger | pending: Map.delete(ledger.pending, result.correlation)}
      {:ok, record(next, result.status, result.correlation), entry, []}
    else
      _ -> {:error, :invalid_or_stale_result}
    end
  end

  def result_work(entry, result, accepted, leases) do
    owner = entry.action.owner

    %{
      class: :message,
      producer: "action-result",
      sequence: entry.action.sequence,
      generation: owner.generation,
      revision: accepted.correlation.revision,
      source: owner,
      target: owner,
      route: :self,
      name: "action-result",
      payload: %{
        version: 1,
        correlation: entry.correlation,
        kind: entry.action.kind,
        status: result.status,
        value: result.value,
        leases: leases,
        selection: entry.selection,
        trust: if(entry.action.kind == :command, do: :untrusted_client, else: :local_capability)
      },
      supersedable: false,
      timer: :none,
      receipt: 0,
      source_stamp: entry.source_stamp,
      target_stamp: entry.source_stamp,
      kind: :action_result,
      origin: :provider
    }
  end

  def live?(entry, accepted) do
    component = RootSchedule.component(accepted, entry.action.owner)

    component != nil and component.schema_digest == entry.source_stamp and
      entry.action.owner.generation == accepted.correlation.generation
  rescue
    _ -> false
  end

  def prune(ledger, accepted) do
    {removed, retained} =
      Enum.split_with(ledger.pending, fn {_, entry} -> not live?(entry, accepted) end)

    next =
      Enum.reduce(removed, %{ledger | pending: Map.new(retained)}, fn {correlation, _}, acc ->
        record(acc, :canceled, correlation)
      end)

    {next, Enum.map(removed, &elem(&1, 1))}
  end

  def snapshot(ledger),
    do: %{
      pending: map_size(ledger.pending),
      leases: map_size(ledger.leases),
      lease_depth: lease_depth(ledger),
      totals: ledger.totals,
      history: ledger.history,
      requests:
        ledger.pending
        |> Map.values()
        |> Enum.map(&Map.take(&1, [:correlation, :selection, :status]))
        |> Enum.sort()
    }

  def lease_depth(ledger),
    do:
      map_size(ledger.leases) +
        Enum.sum(
          Enum.map(ledger.pending, fn {_, entry} ->
            Map.get(entry.declaration, :lease_limit, 0)
          end)
        )

  def record(ledger, status, correlation),
    do: %{
      ledger
      | totals: Map.update(ledger.totals, status, 1, &min(&1 + 1, 9_007_199_254_740_991)),
        history: Enum.take(ledger.history ++ [%{status: status, correlation: correlation}], -128)
    }

  defp validate_control!(ledger, %{kind: :effect_cancel} = action) do
    entry = Map.fetch!(ledger.pending, action.body.correlation)
    true = entry.action.owner == action.owner
    :ok
  end

  defp validate_control!(_, %{kind: kind}) when kind in [:message, :timer_start, :timer_cancel],
    do: :ok

  defp validate_control!(_, _), do: raise(ArgumentError)

  defp select(port, action, declaration) do
    descriptor = %{kind: action.kind, id: action.body.declaration, declaration: declaration}

    case RootPort.call(port, :select, [descriptor]) do
      {status, name} when status in [:granted, :fallback] ->
        true = Schema.name?(name)
        true = status != :fallback or Map.get(declaration, :fallback) == :component
        %{status: status, name: name, fallback: Map.get(declaration, :fallback)}

      _ ->
        %{status: :denied, name: nil, fallback: Map.get(declaration, :fallback)}
    end
  end

  defp result_value(entry, result) do
    schema =
      case result.status do
        :completed -> entry.declaration.result
        :failed -> entry.declaration.error
        _ -> nil
      end

    if schema == nil do
      if result.value == nil, do: :ok, else: {:error, :invalid_result}
    else
      owner = entry.action.owner

      case Schema.normalize(schema, result.value, %{
             kind: :host,
             root: owner.root,
             owner: owner.root
           }) do
        {:ok, value} when value == result.value -> :ok
        _ -> {:error, :invalid_result}
      end
    end
  end
end
