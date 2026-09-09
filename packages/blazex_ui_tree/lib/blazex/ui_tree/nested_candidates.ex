defmodule BlazeX.UITree.NestedCandidates do
  @moduledoc false
  alias BlazeX.Component.{Input, NestedTable, Result}
  alias BlazeX.Core.{Event, Identity}
  alias BlazeX.UITree.CompositionPlan, as: Guard

  def flatten(plan), do: [plan | Enum.flat_map(plan.children, &flatten/1)]
  def fingerprint(plan), do: NestedTable.digest({plan.module, plan.metadata})

  def invocation(plan),
    do:
      if(plan.input, do: Map.take(plan.input, [:props, :slots]), else: %{props: %{}, slots: %{}})

  def role(plan), do: if(plan.input, do: plan.input.role, else: :pure)

  def preflight(plan) do
    Enum.each(flatten(plan), fn item ->
      Guard.require!(Input.portable?(invocation(item)), :nonportable_invocation, item.path)

      if role(item) == :stateful do
        Guard.require!(not Enum.any?(item.identity.path, &ordinal?/1), :unstable_key, item.path)
      end
    end)

    plan
  end

  def evaluate(plan, old_index, revision, sequence, replaced \\ MapSet.new(), event \\ nil) do
    {candidate, records, trace, notifications} =
      visit(plan, old_index, revision, sequence, replaced, event, nil)

    Guard.require!(length(notifications) <= 128, :notification_limit, [])
    {candidate, records, trace, notifications}
  end

  defp visit(plan, old_index, revision, sequence, replaced, event, stateful_parent) do
    previous = Map.get(old_index, plan.identity)
    fresh = previous == nil or MapSet.member?(replaced, plan.identity)
    compatible = previous == nil or previous.schema_digest == fingerprint(plan)
    Guard.require!(fresh or compatible, :replacement_required, plan.path)
    stateful = role(plan) == :stateful
    old_state = if previous, do: previous.state, else: :absent

    input =
      if plan.input,
        do: %{plan.input | revision: revision, sequence: sequence, state: old_state},
        else: nil

    target = stateful_parent || root(plan.identity)

    {state, state_trace, notifications} =
      cond do
        not stateful ->
          {:absent, [], []}

        fresh ->
          result = callback(plan, :init, %{input | state: :absent, transition: :init})
          {state, notices} = transition(result, :init, :absent, plan, target, sequence)
          {state, [observe(:init, plan)], notices}

        event != nil and event.target == plan.identity ->
          payload = %{
            name: event.value.name,
            data: event.value.payload,
            source: Map.from_struct(event.value.source)
          }

          result =
            callback(plan, :handle_event, %{
              input
              | transition: :handle_event,
                payload: {:present, payload}
            })

          {state, notices} = transition(result, :handle_event, old_state, plan, target, sequence)
          {state, [observe(:local_event, plan)], notices}

        previous.invocation != invocation(plan) and function_exported?(plan.module, :update, 1) ->
          result = callback(plan, :update, %{input | transition: :update})
          {state, notices} = transition(result, :update, old_state, plan, target, sequence)

          {state, [observe(if(result == :no_change, do: :no_change, else: :update), plan)],
           notices}

        true ->
          {old_state, [observe(:no_change, plan)], []}
      end

    output =
      if plan.data do
        plan.data
      else
        result = callback(plan, :render, %{input | transition: :render, state: state})

        case result do
          {:output, {:semantic, 1, value}} -> value
          _ -> Guard.fail(:invalid_result, plan.path)
        end
      end

    record = %{
      identity: plan.identity,
      parent: parent(plan.identity),
      module: plan.module,
      public_id: plan.public_id,
      role: role(plan),
      contract: "0.1.0-bh05-nested-state",
      schema_digest: fingerprint(plan),
      invocation: invocation(plan),
      invocation_digest: NestedTable.digest(invocation(plan)),
      state: state,
      output_digest: NestedTable.digest(output),
      generation: plan.identity.generation,
      revision: revision,
      sequence: sequence,
      status: :accepted,
      owned_actions: []
    }

    children =
      Enum.map(
        plan.children,
        &visit(
          &1,
          old_index,
          revision,
          sequence,
          replaced,
          event,
          if(stateful, do: plan.identity, else: stateful_parent)
        )
      )

    child_candidates = Enum.map(children, &elem(&1, 0))

    candidate = %{
      identity: plan.identity,
      output: output,
      children: child_candidates,
      path: plan.path,
      public_id: plan.public_id,
      capabilities: if(plan.input, do: plan.input.capabilities, else: [])
    }

    action_trace =
      Enum.map(notifications, fn notice ->
        Map.put(observe(:notification, plan), :name, notice.name)
      end)

    disposition =
      cond do
        previous == nil -> :insert
        fresh -> :replace
        true -> :retain
      end

    trace =
      [observe(disposition, plan)] ++ state_trace ++ [observe(:render, plan)] ++ action_trace

    {candidate, [record | Enum.flat_map(children, &elem(&1, 1))],
     trace ++ Enum.flat_map(children, &elem(&1, 2)),
     notifications ++ Enum.flat_map(children, &elem(&1, 3))}
  end

  def callback(plan, name, input) do
    Guard.require!(function_exported?(plan.module, name, 1), :missing_callback, plan.path)

    result =
      try do
        apply(plan.module, name, [input])
      rescue
        _ -> Guard.fail(:callback_failed, plan.path)
      catch
        _, _ -> Guard.fail(:callback_failed, plan.path)
      end

    Guard.require!(Result.validate(role(plan), name, result) == :ok, :invalid_result, plan.path)

    case result do
      {:rejected, _} -> Guard.fail(:callback_rejected, plan.path)
      _ -> result
    end
  end

  defp transition({:state, value}, _name, _old, _plan, _target, _sequence),
    do: {{:present, value}, []}

  defp transition(:no_change, name, old, _plan, _target, _sequence) when name != :init,
    do: {old, []}

  defp transition({:actions, value, actions}, name, _old, plan, target, sequence)
       when name in [:update, :handle_event] do
    notices =
      Enum.map(actions, fn
        {:message, "parent", %{name: event, payload: payload} = data} when map_size(data) == 2 ->
          Guard.require!(
            Event.name?(event) and is_map(payload) and Input.portable?(payload),
            :notification,
            plan.path
          )

          %{
            source: plan.identity,
            target: target,
            name: event,
            payload: payload,
            sequence: sequence
          }

        _ ->
          Guard.fail(:prohibited_action, plan.path)
      end)

    {{:present, value}, notices}
  end

  defp transition(_, _name, _old, plan, _target, _sequence),
    do: Guard.fail(:invalid_transition, plan.path)

  defp ordinal?({_, _, _, {:ordinal, _}}), do: true
  defp ordinal?(_), do: false
  defp root(identity), do: elem(Identity.new(identity.root, identity.generation), 1)
  defp parent(%{path: []}), do: nil
  defp parent(identity), do: %{identity | path: Enum.drop(identity.path, -1)}
  defp observe(event, plan), do: %{event: event, component: plan.public_id, path: plan.path}
end
