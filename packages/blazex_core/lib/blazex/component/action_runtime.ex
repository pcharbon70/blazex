defmodule BlazeX.Component.ActionRuntime do
  @moduledoc false
  alias BlazeX.Component.{
    Action,
    ActionLedger,
    ActionManifest,
    ActionPort,
    RecoveryPort,
    RootPort,
    SchedulingIntents
  }

  @inventory_timeout 1000

  defstruct [:manifest, :port, :cleanup_session, ledger: %ActionLedger{}, timers: %{}]

  def new(nil), do: {:ok, nil}

  def new(%{manifest: manifest, port: port} = config) when map_size(config) == 2 do
    with :ok <- validate(config), {:ok, session} <- RecoveryPort.open_session() do
      {:ok, %__MODULE__{manifest: manifest, port: port, cleanup_session: session}}
    else
      _ -> {:error, :invalid_actions}
    end
  end

  def new(_), do: {:error, :invalid_actions}

  def validate(nil), do: :ok

  def validate(%{manifest: manifest, port: port} = config) when map_size(config) == 2 do
    with :ok <- ActionManifest.validate(manifest), true <- ActionPort.valid?(port) do
      :ok
    else
      _ -> {:error, :invalid_actions}
    end
  end

  def validate(_), do: {:error, :invalid_actions}

  def prepare(runtime, groups, candidate, spec, policy, evaluator) do
    with {:ok, plan} <-
           ActionLedger.prepare(
             runtime.ledger,
             groups,
             candidate,
             spec,
             runtime.manifest,
             runtime.port
           ),
         true <-
           Enum.all?(
             plan.actions,
             &(RootPort.call(evaluator, :admit_action, [&1, candidate]) == :ok)
           ),
         local <-
           Enum.filter(plan.actions, &(&1.kind in [:message, :timer_start, :timer_cancel])),
         groups <- Enum.map(local, &%{source: &1.owner, actions: [local_tuple(&1)]}),
         {:ok, intents} <- SchedulingIntents.normalize(policy, groups, candidate, spec) do
      ghosts =
        Enum.filter(plan.actions, &Map.has_key?(&1, :request))
        |> Enum.map(fn action ->
          {:ok, result} = Action.result(action.request.correlation, :denied)
          ActionLedger.result_work(action.request, result, candidate, [])
        end)

      {:ok,
       Map.merge(plan, %{
         local: intents,
         reservations: Enum.filter(intents, &(&1.kind == :message)) ++ ghosts
       })}
    else
      _ -> {:error, :invalid_action_batch}
    end
  end

  def commit(runtime, plan, accepted, checkpoint \\ fn _ -> :ok end) do
    runtime = %{runtime | ledger: %{runtime.ledger | sequences: plan.sequences}}

    Enum.reduce(plan.actions, {runtime, []}, fn action, {runtime, work} ->
      case action.kind do
        kind when kind in [:effect_request, :command] ->
          entry = action.request
          runtime = %{runtime | ledger: ActionLedger.install(runtime.ledger, entry)}
          checkpoint.(runtime)

          status =
            if entry.selection.status == :denied,
              do: :denied,
              else: RootPort.call(runtime.port, :submit, [entry])

          if status == :accepted do
            token = make_ref()

            ref =
              Process.send_after(
                self(),
                {:action_timeout, entry.correlation, token},
                action.body.timeout_ms
              )

            {%{
               runtime
               | timers:
                   Map.put(runtime.timers, entry.correlation, %{reference: ref, token: token})
             }, work}
          else
            status = if status in [:denied, :disconnected], do: status, else: :disconnected
            {:ok, result} = Action.result(entry.correlation, status)
            {:ok, runtime, item} = complete(runtime, result, accepted)
            {runtime, work ++ [item]}
          end

        :effect_cancel ->
          case Map.get(runtime.ledger.pending, action.body.correlation) do
            nil ->
              {runtime, work}

            entry ->
              canceled = RootPort.call(runtime.port, :cancel, [entry])

              {:ok, result} =
                Action.result(
                  entry.correlation,
                  if(canceled == :ok, do: :canceled, else: :disconnected)
                )

              {:ok, runtime, item} = complete(runtime, result, accepted)
              {runtime, work ++ [item]}
          end

        :resource_transfer ->
          ledger = ActionLedger.transfer(runtime.ledger, action, accepted)
          runtime = %{runtime | ledger: ledger}
          lease = Map.fetch!(ledger.leases, action.body.lease.id)
          {replace(runtime, [lease]), work}

        :resource_release ->
          {release(runtime, action.body.lease), work}

        _ ->
          {runtime, work}
      end
    end)
  end

  def complete(runtime, result, accepted) do
    case ActionLedger.complete(runtime.ledger, result, accepted) do
      {:ok, ledger, entry, leases} ->
        runtime = cancel_timeout(runtime, result.correlation)
        runtime = %{runtime | ledger: ledger}
        runtime = register(runtime, Enum.map(result.leases, &Map.fetch!(ledger.leases, &1)))

        {:ok, runtime, ActionLedger.result_work(entry, result, accepted, leases)}

      error ->
        error
    end
  end

  def timeout(runtime, correlation, token, accepted) do
    case Map.get(runtime.timers, correlation) do
      %{token: ^token} ->
        entry = Map.fetch!(runtime.ledger.pending, correlation)
        RootPort.call(runtime.port, :cancel, [entry])
        {:ok, result} = Action.result(correlation, :timed_out)
        complete(runtime, result, accepted)

      _ ->
        {:error, :stale_timeout}
    end
  end

  def prune(nil, _), do: nil

  def prune(runtime, accepted) do
    {ledger, removed} = ActionLedger.prune(runtime.ledger, accepted)

    runtime =
      Enum.reduce(removed, %{runtime | ledger: ledger}, fn entry, acc ->
        result = RootPort.call(acc.port, :cancel, [entry])
        acc = cancel_timeout(acc, entry.correlation)

        if result == :ok,
          do: acc,
          else: %{acc | ledger: ActionLedger.record(acc.ledger, :disconnected, entry.correlation)}
      end)

    runtime =
      Enum.reduce(runtime.ledger.leases, runtime, fn {_, lease}, acc ->
        if ActionLedger.lease_live?(lease, accepted),
          do: acc,
          else: release(acc, ActionLedger.lease_ref(lease))
      end)

    sequences =
      Map.filter(runtime.ledger.sequences, fn {owner, _} ->
        owner.generation == accepted.correlation.generation
      end)

    %{runtime | ledger: %{runtime.ledger | sequences: sequences}}
  end

  def finish_result(nil, _, _), do: nil

  def finish_result(runtime, %{kind: :action_result, payload: %{leases: leases}}, false),
    do: Enum.reduce(leases, runtime, &release(&2, &1))

  def finish_result(runtime, _, _), do: runtime

  defp release(runtime, reference) do
    case Map.get(runtime.ledger.leases, reference.id) do
      %{acquisition: acquisition} = lease when acquisition == reference.acquisition ->
        lease = %{lease | release_requested: true}

        status =
          if RootPort.call(runtime.port, :release, [lease]) == :released,
            do: :released,
            else: :lost

        runtime = %{runtime | ledger: ActionLedger.released(runtime.ledger, lease, status)}
        %{runtime | cleanup_session: drop(runtime.cleanup_session, [lease.id])}

      _ ->
        runtime
    end
  end

  def close(nil, _), do: nil

  def close(runtime, reason) do
    next =
      Enum.reduce(runtime.ledger.pending, runtime, fn {correlation, entry}, acc ->
        canceled = RootPort.call(acc.port, :cancel, [entry])
        acc = cancel_timeout(acc, correlation)

        %{
          acc
          | ledger:
              ActionLedger.record(
                acc.ledger,
                if(reason == :runtime_loss or canceled != :ok, do: :disconnected, else: :canceled),
                correlation
              )
        }
      end)

    next =
      Enum.reduce(next.ledger.leases, next, fn {_, lease}, acc ->
        release(acc, ActionLedger.lease_ref(lease))
      end)

    # A rejected replacement still belongs to the old generation. Keep its
    # watermarks until a new generation actually commits (prune/2).
    next = %{next | ledger: %{next.ledger | pending: %{}}}
    %{next | cleanup_session: close_session(next.cleanup_session)}
  end

  def snapshot(runtime), do: ActionLedger.snapshot(runtime.ledger)
  def pending(runtime), do: map_size(runtime.ledger.pending)

  def seed_inventory(%__MODULE__{} = runtime) do
    session = runtime.cleanup_session || new_session()

    session =
      runtime.ledger
      |> ActionLedger.ordered_leases()
      |> Enum.chunk_every(RecoveryPort.maximum_page_size())
      |> Enum.reduce(session, fn page, current -> register_page(current, runtime.port, page) end)

    finish_inventory_transfer(%{
      runtime
      | cleanup_session: session,
        ledger: ActionLedger.compact_inventory(runtime.ledger)
    })
  end

  def reset_cleanup_session(%__MODULE__{cleanup_session: %{alive: true}} = runtime),
    do: %{runtime | cleanup_session: RecoveryPort.reset_cleanup_stats(runtime.cleanup_session)}

  def reset_cleanup_session(runtime), do: runtime

  def put_cleanup_session(%__MODULE__{} = runtime, session),
    do: %{runtime | cleanup_session: session}

  def close_cleanup_session(%__MODULE__{} = runtime),
    do: %{runtime | cleanup_session: close_session(runtime.cleanup_session)}

  defp cancel_timeout(runtime, correlation) do
    case Map.pop(runtime.timers, correlation) do
      {nil, _} ->
        runtime

      {%{reference: ref}, timers} ->
        Process.cancel_timer(ref)
        %{runtime | timers: timers}
    end
  end

  defp register(runtime, []), do: runtime

  defp register(runtime, leases) do
    session = runtime.cleanup_session || new_session()
    %{runtime | cleanup_session: register_page(session, runtime.port, leases)}
  end

  defp register_page(%{alive: true} = session, port, leases) do
    case RootPort.prepare_release_page(port, leases) do
      {:ok, tickets} ->
        session = RecoveryPort.note_ticket_preparation(session, tickets, :ok)

        case RecoveryPort.register_page(session, tickets, @inventory_timeout) do
          {:ok, updated} -> updated
          {:error, _, updated} -> updated
        end

      _ ->
        RecoveryPort.note_ticket_preparation(session, length(leases), :error)
    end
  end

  defp register_page(session, _port, _leases), do: session

  defp replace(%{cleanup_session: %{alive: true} = session} = runtime, leases) do
    case RootPort.prepare_release_page(runtime.port, leases) do
      {:ok, tickets} ->
        session = RecoveryPort.note_ticket_preparation(session, tickets, :ok)

        case RecoveryPort.replace_page(session, tickets, @inventory_timeout) do
          {:ok, updated} -> %{runtime | cleanup_session: updated}
          {:error, _, updated} -> %{runtime | cleanup_session: updated}
        end

      _ ->
        updated = RecoveryPort.note_ticket_preparation(session, length(leases), :error)
        %{runtime | cleanup_session: updated}
    end
  end

  defp replace(runtime, _leases), do: runtime

  defp drop(%{alive: true} = session, identities) do
    case RecoveryPort.drop_page(session, identities, @inventory_timeout) do
      {:ok, updated} -> updated
      {:error, _, updated} -> updated
    end
  end

  defp drop(session, _identities), do: session

  defp new_session do
    {:ok, session} = RecoveryPort.open_session()
    session
  end

  defp close_session(nil), do: nil
  defp close_session(session), do: RecoveryPort.close_session(session)

  defp finish_inventory_transfer(runtime) do
    :erlang.garbage_collect()
    runtime
  end

  defp local_tuple(%{kind: :message, body: body}),
    do: {:message, Atom.to_string(body.route), Map.take(body, [:target, :name, :payload])}

  defp local_tuple(%{kind: :timer_start, body: body}),
    do: {:timer, body.timer_id, body |> Map.delete(:timer_id) |> Map.put(:operation, :start)}

  defp local_tuple(%{kind: :timer_cancel, body: body}),
    do: {:timer, body.timer_id, %{operation: :cancel}}
end
