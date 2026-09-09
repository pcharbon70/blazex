defmodule BlazeX.Component.ActionRuntime do
  @moduledoc false
  alias BlazeX.Component.{
    Action,
    ActionLedger,
    ActionManifest,
    ActionPort,
    RootPort,
    SchedulingIntents
  }

  defstruct [:manifest, :port, ledger: %ActionLedger{}, timers: %{}]

  def new(nil), do: {:ok, nil}

  def new(%{manifest: manifest, port: port} = config) when map_size(config) == 2 do
    with :ok <- ActionManifest.validate(manifest), true <- ActionPort.valid?(port) do
      {:ok, %__MODULE__{manifest: manifest, port: port}}
    else
      _ -> {:error, :invalid_actions}
    end
  end

  def new(_), do: {:error, :invalid_actions}

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
          {%{runtime | ledger: ActionLedger.transfer(runtime.ledger, action, accepted)}, work}

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

        {:ok, %{runtime | ledger: ledger},
         ActionLedger.result_work(entry, result, accepted, leases)}

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

        %{runtime | ledger: ActionLedger.released(runtime.ledger, lease, status)}

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
    %{next | ledger: %{next.ledger | pending: %{}}}
  end

  def snapshot(runtime), do: ActionLedger.snapshot(runtime.ledger)
  def pending(runtime), do: map_size(runtime.ledger.pending)

  defp cancel_timeout(runtime, correlation) do
    case Map.pop(runtime.timers, correlation) do
      {nil, _} ->
        runtime

      {%{reference: ref}, timers} ->
        Process.cancel_timer(ref)
        %{runtime | timers: timers}
    end
  end

  defp local_tuple(%{kind: :message, body: body}),
    do: {:message, Atom.to_string(body.route), Map.take(body, [:target, :name, :payload])}

  defp local_tuple(%{kind: :timer_start, body: body}),
    do: {:timer, body.timer_id, body |> Map.delete(:timer_id) |> Map.put(:operation, :start)}

  defp local_tuple(%{kind: :timer_cancel, body: body}),
    do: {:timer, body.timer_id, %{operation: :cancel}}
end
