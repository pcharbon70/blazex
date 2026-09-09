defmodule BlazeX.Component.SchedulingIntents do
  @moduledoc false
  alias BlazeX.Component.{RootSchedule, Schema}

  def normalize(policy, groups, candidate, spec) do
    with true <- is_list(groups) and length(groups) <= 128 do
      items =
        Enum.flat_map(groups, fn %{source: source, actions: actions} = group ->
          true = map_size(group) == 2
          true = is_list(actions) and length(actions) <= 16
          Enum.map(actions, &one(policy, source, &1, candidate, spec))
        end)

      if length(items) <= 16, do: {:ok, items}, else: {:error, :intent_limit}
    else
      _ -> {:error, :invalid_intent}
    end
  rescue
    _ -> {:error, :invalid_intent}
  catch
    _, _ -> {:error, :invalid_intent}
  end

  defp one(policy, source, {:timer, id, %{operation: :cancel} = data}, candidate, _spec) do
    true = map_size(data) == 1 and Schema.name?(id)
    component = RootSchedule.component(candidate, source)

    true =
      component.role in [:root, :stateful] and
        Map.has_key?(policy.components, component.public_id)

    %{
      class: :timer,
      producer: "component",
      sequence: 1,
      generation: candidate.correlation.generation,
      revision: candidate.correlation.revision,
      source: source,
      target: source,
      route: :self,
      name: "cancel",
      payload: %{},
      supersedable: false,
      timer: %{operation: :cancel, id: id},
      receipt: 0,
      source_stamp: component.schema_digest,
      target_stamp: component.schema_digest,
      kind: :timer_cancel,
      origin: :component
    }
  end

  defp one(policy, source, {kind, id, data}, candidate, spec) when kind in [:message, :timer] do
    component = RootSchedule.component(candidate, source)
    true = component.role in [:root, :stateful]
    routes = Map.fetch!(policy.components, component.public_id)

    {route, timer, data} =
      if kind == :message do
        true = Enum.sort(Map.keys(data)) == [:name, :payload, :target]

        route =
          Map.fetch!(
            %{"self" => :self, "child" => :child, "parent" => :parent, "root" => :root},
            id
          )

        {route, :none, data}
      else
        true =
          Enum.sort(Map.keys(data)) == [
            :delay,
            :interval,
            :name,
            :operation,
            :payload,
            :route,
            :target
          ]

        true = data.operation == :start

        {data.route, %{operation: :start, id: id, delay: data.delay, interval: data.interval},
         data}
      end

    grant = %{
      component: component.public_id,
      classes: [:message, :timer],
      routes: routes,
      supersedable: []
    }

    local_policy = %{policy | producers: %{"component" => grant}}

    envelope = %{
      class: kind,
      producer: "component",
      sequence: 1,
      generation: candidate.correlation.generation,
      revision: candidate.correlation.revision,
      source: source,
      target: data.target,
      route: route,
      name: data.name,
      payload: data.payload,
      supersedable: false,
      timer: timer
    }

    {:ok, item} = RootSchedule.normalize(local_policy, envelope, candidate, spec)
    %{item | origin: :component}
  end
end
