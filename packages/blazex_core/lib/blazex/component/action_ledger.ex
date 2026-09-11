defmodule BlazeX.Component.ActionLedger do
  @moduledoc false
  alias BlazeX.Component.{Action, ActionManifest, RootPort, RootSchedule, Schema}
  defstruct pending: %{}, leases: %{}, lease_order: [], sequences: %{}, history: [], totals: %{}

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
    controls = Enum.filter(actions, &(&1.kind in [:resource_transfer, :resource_release]))
    true = length(Enum.uniq_by(controls, & &1.body.lease)) == length(controls)

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
            validate_control!(ledger, action, candidate, manifest)
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
         true <- length(result.leases) <= Map.get(entry.declaration, :lease_limit, 0),
         true <- Enum.all?(result.leases, &(not Map.has_key?(ledger.leases, &1))) do
      next = %{
        ledger
        | pending: Map.delete(ledger.pending, result.correlation),
          lease_order: ledger.lease_order ++ result.leases
      }

      next =
        Enum.reduce(result.leases, next, fn id, acc ->
          lease = %{
            id: id,
            owner: entry.action.owner,
            generation: entry.action.owner.generation,
            kind: entry.declaration.lease_kind,
            capability: entry.declaration.capability,
            acquisition: entry.correlation,
            selection: entry.selection,
            source_stamp: entry.source_stamp,
            transfer_history: [],
            release_requested: false,
            status: :acquired
          }

          record(%{acc | leases: Map.put(acc.leases, id, lease)}, :acquired, lease_ref(lease))
        end)

      {:ok, record(next, result.status, result.correlation), entry,
       Enum.map(result.leases, &%{id: &1, acquisition: entry.correlation})}
    else
      _ -> {:error, :invalid_or_stale_result}
    end
  end

  def lease_ref(lease), do: Map.take(lease, [:id, :acquisition])

  def lease_live?(lease, accepted) do
    live?(%{action: %{owner: lease.owner}, source_stamp: lease.source_stamp}, accepted)
  end

  def transfer(ledger, action, accepted) do
    lease = Map.fetch!(ledger.leases, action.body.lease.id)
    target = RootSchedule.component(accepted, action.body.target)

    lease = %{
      lease
      | owner: action.body.target,
        source_stamp: target.schema_digest,
        status: :transferred,
        transfer_history:
          lease.transfer_history ++
            [
              %{
                from: lease.owner,
                to: action.body.target,
                action: action.id,
                sequence: action.sequence
              }
            ]
    }

    record(
      %{ledger | leases: Map.put(ledger.leases, lease.id, lease)},
      :transferred,
      lease_ref(lease)
    )
  end

  def released(ledger, lease, status) when status in [:released, :lost],
    do:
      record(
        %{
          ledger
          | leases: Map.delete(ledger.leases, lease.id),
            lease_order: List.delete(ledger.lease_order, lease.id)
        },
        status,
        lease_ref(lease)
      )

  def released_many(ledger, releases) when is_list(releases) and length(releases) <= 512 do
    true =
      Enum.all?(releases, fn {lease, status} -> is_map(lease) and status in [:released, :lost] end)

    {released, lost} =
      Enum.reduce(releases, {0, 0}, fn
        {_, :released}, {released, lost} -> {released + 1, lost}
        {_, :lost}, {released, lost} -> {released, lost + 1}
      end)

    totals = ledger.totals |> add_total(:released, released) |> add_total(:lost, lost)

    history =
      releases
      |> Enum.take(-128)
      |> Enum.map(fn {lease, status} ->
        %{status: status, correlation: lease_ref(lease)}
      end)

    {leases, lease_order} =
      if length(releases) == map_size(ledger.leases) do
        {%{}, []}
      else
        ids = MapSet.new(releases, fn {lease, _} -> lease.id end)

        {Map.drop(ledger.leases, MapSet.to_list(ids)),
         Enum.reject(ledger.lease_order, &(&1 in ids))}
      end

    %{
      ledger
      | leases: leases,
        lease_order: lease_order,
        totals: totals,
        history:
          if(length(releases) >= 128,
            do: history,
            else: Enum.take(ledger.history ++ history, -128)
          )
    }
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
      inventory_pages:
        ledger
        |> ordered_leases()
        |> Enum.map(&Map.drop(&1, [:selection, :source_stamp]))
        |> Enum.chunk_every(128),
      requests:
        ledger.pending
        |> Map.values()
        |> Enum.map(&Map.take(&1, [:correlation, :selection, :status]))
        |> Enum.sort()
    }

  def ordered_leases(ledger) do
    if length(ledger.lease_order) == map_size(ledger.leases) do
      Enum.map(ledger.lease_order, &Map.fetch!(ledger.leases, &1))
    else
      Enum.sort_by(Map.values(ledger.leases), & &1.id)
    end
  end

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

  defp add_total(totals, _status, 0), do: totals

  defp add_total(totals, status, count),
    do: Map.update(totals, status, count, &min(&1 + count, 9_007_199_254_740_991))

  defp validate_control!(ledger, %{kind: :effect_cancel} = action, _, _) do
    entry = Map.fetch!(ledger.pending, action.body.correlation)
    true = entry.action.owner == action.owner
    :ok
  end

  defp validate_control!(ledger, %{kind: kind} = action, candidate, manifest)
       when kind in [:resource_transfer, :resource_release] do
    lease = Map.fetch!(ledger.leases, action.body.lease.id)
    true = lease_ref(lease) == action.body.lease and lease.owner == action.owner
    true = lease_live?(lease, candidate)

    if kind == :resource_transfer do
      target = RootSchedule.component(candidate, action.body.target)
      source = RootSchedule.component(candidate, action.owner)
      true = target != nil and target.role in [:root, :stateful]

      true =
        action.body.target.root == action.owner.root and
          action.body.target.generation == action.owner.generation

      true = length(lease.transfer_history) < 16

      true =
        Enum.any?(
          manifest.owners[source.public_id].transfers,
          &RootSchedule.route?(&1, action.owner, action.body.target, candidate)
        )
    end

    :ok
  end

  defp validate_control!(_, %{kind: kind}, _, _)
       when kind in [:message, :timer_start, :timer_cancel],
       do: :ok

  defp validate_control!(_, _, _, _), do: raise(ArgumentError)

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
