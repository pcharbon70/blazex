defmodule BlazeX.Component.RootSchedule do
  @moduledoc """
  Immutable, opt-in root admission and FIFO scheduling. Bounds include queued,
  active and candidate-reserved work. This is not a bound on a privileged VM
  caller's raw mailbox. Policy and producer capabilities are runtime-owned.
  """
  alias BlazeX.Component.{Input, NestedTable, RootPort, Schema}
  alias BlazeX.Core.{Event, Identity}

  @keys [
    :class,
    :producer,
    :sequence,
    :generation,
    :revision,
    :source,
    :target,
    :route,
    :name,
    :payload,
    :supersedable,
    :timer
  ]
  @classes [:event, :update, :message, :timer]
  @routes [:self, :child, :parent, :root]
  @limits %{event: 256, update: 64, message: 128, timer: 32}
  defstruct [
    :policy,
    queue: [],
    active: nil,
    reserved: [],
    producers: %{},
    receipt: 0,
    admitted: 0,
    rejected: 0,
    coalesced: 0,
    maximum: 0
  ]

  def version, do: "0.1.0-bh05-scheduling"
  def new(nil), do: {:ok, nil}

  def new(policy) do
    if policy?(policy), do: {:ok, %__MODULE__{policy: policy}}, else: {:error, :invalid_policy}
  end

  def policy?(policy) do
    with true <- keys?(policy, [:producers, :events, :messages, :components]),
         true <- byte_size(:erlang.term_to_binary(policy)) <= 65_536,
         true <- bounded_map?(policy.producers, 32) and map_size(policy.producers) > 0,
         true <-
           Enum.all?(policy.producers, fn {name, grant} ->
             Schema.name?(name) and keys?(grant, [:component, :classes, :routes, :supersedable]) and
               Schema.name?(grant.component) and subset?(grant.classes, @classes) and
               subset?(grant.routes, @routes) and subset?(grant.supersedable, [:event, :update]) and
               Enum.all?(grant.supersedable, &(&1 in grant.classes))
           end),
         true <-
           bounded_map?(policy.events, 32) and
             Enum.all?(policy.events, fn {name, schema} ->
               Event.name?(name) and Schema.host?(schema)
             end),
         true <-
           bounded_map?(policy.messages, 128) and
             Enum.all?(policy.messages, fn {component, declarations} ->
               Schema.name?(component) and bounded_map?(declarations, 32) and
                 Enum.all?(declarations, fn {name, schema} ->
                   Schema.name?(name) and Schema.host?(schema)
                 end)
             end),
         true <-
           bounded_map?(policy.components, 128) and
             Enum.all?(policy.components, fn {component, routes} ->
               Schema.name?(component) and subset?(routes, @routes)
             end) do
      true
    else
      _ -> false
    end
  rescue
    _ -> false
  end

  def admit(schedule, envelope, accepted, spec) do
    with {:ok, item} <- normalize(schedule.policy, envelope, accepted, spec),
         true <- item.sequence == Map.get(schedule.producers, item.producer, 0) + 1,
         true <- NestedTable.counter?(schedule.receipt + 1 + length(schedule.reserved)),
         {:ok, next, superseded} <- insert(schedule, item) do
      item = %{item | receipt: schedule.receipt + 1}

      next =
        %{
          next
          | queue: if(item.kind == :timer_cancel, do: next.queue, else: next.queue ++ [item]),
            receipt: item.receipt,
            producers: Map.put(next.producers, item.producer, item.sequence),
            admitted: next.admitted + 1,
            coalesced: next.coalesced + if(superseded, do: 1, else: 0)
        }
        |> sample()

      {:ok, item, superseded, next}
    else
      {:error, code} -> {:error, code, reject(schedule)}
      _ -> {:error, :stale_sequence, reject(schedule)}
    end
  end

  def reject(schedule),
    do: %{schedule | rejected: min(schedule.rejected + 1, 9_007_199_254_740_991)}

  def normalize(policy, envelope, accepted, spec) do
    with true <- keys?(envelope, @keys) and Input.portable?(envelope),
         true <- byte_size(:erlang.term_to_binary(envelope)) <= 16_384,
         true <- accepted != nil,
         true <-
           envelope.class in @classes and envelope.route in @routes and
             is_boolean(envelope.supersedable),
         true <- NestedTable.counter?(envelope.sequence) and envelope.sequence > 0,
         true <-
           envelope.generation == accepted.correlation.generation and
             envelope.revision == accepted.correlation.revision,
         grant when is_map(grant) <- Map.get(policy.producers, envelope.producer),
         true <- envelope.class in grant.classes and envelope.route in grant.routes,
         true <- not envelope.supersedable or envelope.class in grant.supersedable,
         source when is_map(source) <- component(accepted, envelope.source),
         target when is_map(target) <- component(accepted, envelope.target),
         true <- source.public_id == grant.component and target.role in [:root, :stateful],
         true <- envelope.class != :timer or source.role in [:root, :stateful],
         true <- route?(envelope.route, source.identity, target.identity, accepted),
         {:ok, payload} <- payload(policy, envelope, source, target, spec),
         true <- timer?(envelope) do
      {:ok,
       Map.merge(envelope, %{
         payload: payload,
         receipt: 0,
         source_stamp: source.schema_digest,
         target_stamp: target.schema_digest,
         kind: kind(envelope),
         origin: :external
       })}
    else
      _ -> {:error, :invalid_ingress}
    end
  rescue
    _ -> {:error, :invalid_ingress}
  end

  def valid_dispatch?(item, accepted) do
    with true <- accepted != nil and item.generation == accepted.correlation.generation,
         source when is_map(source) <- component(accepted, item.source),
         target when is_map(target) <- component(accepted, item.target) do
      source.schema_digest == item.source_stamp and target.schema_digest == item.target_stamp and
        target.role in [:root, :stateful] and
        route?(item.route, item.source, item.target, accepted)
    else
      _ -> false
    end
  end

  def select(%{active: nil, queue: [item | rest]} = schedule),
    do: {:ok, item, %{schedule | queue: rest, active: item}}

  def select(schedule), do: {:empty, schedule}
  def finish(schedule), do: %{schedule | active: nil, reserved: []}

  def reserve(schedule, items) do
    next = %{schedule | reserved: items}

    if length(items) <= 16 and NestedTable.counter?(schedule.receipt + length(items)) and
         within?(next),
       do: {:ok, sample(next)},
       else: {:error, :overload}
  end

  def followups(schedule, items) do
    Enum.reduce_while(items, {:ok, %{schedule | reserved: []}, []}, fn item,
                                                                       {:ok, next, admitted} ->
      case internal(next, item) do
        {:ok, item, next} -> {:cont, {:ok, next, admitted ++ [item]}}
        error -> {:halt, error}
      end
    end)
  end

  def internal(schedule, item) do
    item = %{item | receipt: schedule.receipt + 1}

    next = %{
      schedule
      | queue: schedule.queue ++ [item],
        receipt: item.receipt,
        admitted: schedule.admitted + 1
    }

    if NestedTable.counter?(item.receipt + length(schedule.reserved)) and within?(next),
      do: {:ok, item, sample(next)},
      else: {:error, :overload}
  end

  def drop(schedule, predicate) do
    {removed, kept} = Enum.split_with(schedule.queue, predicate)
    {removed, %{schedule | queue: kept}}
  end

  def metrics(schedule) do
    %{
      depth: depth(schedule),
      queued: length(schedule.queue),
      active: if(schedule.active, do: 1, else: 0),
      reserved: length(schedule.reserved),
      maximum: schedule.maximum,
      classes: counts(schedule),
      admitted: schedule.admitted,
      rejected: schedule.rejected,
      coalesced: schedule.coalesced,
      receipt: schedule.receipt,
      queued_receipts: Enum.map(schedule.queue, & &1.receipt)
    }
  end

  def component(accepted, identity) do
    if identity?(identity),
      do: Enum.find(accepted.state.components, &(&1.identity == identity)),
      else: nil
  rescue
    _ -> nil
  end

  def identity?(identity) do
    keys?(identity, [:root, :path, :generation]) and Identity.valid?(struct(Identity, identity))
  end

  def route?(:self, source, target, _), do: source == target
  def route?(:root, source, target, _), do: same_root?(source, target) and target.path == []
  def route?(:child, source, target, _), do: contains?(source, target) and source != target

  def route?(:parent, source, target, accepted) do
    parent =
      accepted.state.components
      |> Enum.filter(
        &(&1.role in [:root, :stateful] and &1.identity != source and
            contains?(&1.identity, source))
      )
      |> Enum.max_by(&length(&1.identity.path), fn -> nil end)

    parent != nil and parent.identity == target
  end

  def route?(_, _, _, _), do: false

  defp payload(_policy, %{class: :update, name: "props", payload: payload}, source, target, spec) do
    with true <- source.role == :root and target.identity == source.identity,
         true <- keys?(payload, [:props, :slots]),
         {:ok, normalized} <-
           RootPort.normalize(%{spec | props: payload.props, slots: payload.slots}) do
      {:ok, Map.take(normalized, [:props, :slots])}
    else
      _ -> {:error, :invalid_payload}
    end
  end

  defp payload(policy, %{class: :event} = item, _source, _target, spec),
    do: schema_payload(Map.get(policy.events, item.name), item.payload, spec)

  defp payload(policy, %{class: class} = item, _source, target, spec)
       when class in [:message, :timer],
       do:
         schema_payload(
           get_in(policy.messages, [target.public_id, item.name]),
           item.payload,
           spec
         )

  defp payload(_, _, _, _, _), do: {:error, :invalid_payload}

  defp schema_payload(schema, payload, spec),
    do: Schema.normalize(schema, payload, %{kind: :host, root: spec.root, owner: spec.root})

  defp timer?(%{class: :timer, supersedable: false, timer: %{operation: :start} = timer}) do
    keys?(timer, [:operation, :id, :delay, :interval]) and Schema.name?(timer.id) and
      is_integer(timer.delay) and timer.delay in 10..60_000 and
      (timer.interval == nil or (is_integer(timer.interval) and timer.interval in 10..60_000))
  end

  defp timer?(%{class: :timer, supersedable: false, timer: %{operation: :cancel} = timer}),
    do: keys?(timer, [:operation, :id]) and Schema.name?(timer.id)

  defp timer?(%{class: class, timer: :none}) when class in [:event, :update, :message], do: true
  defp timer?(_), do: false
  defp kind(%{class: :timer, timer: %{operation: :start}}), do: :timer_start
  defp kind(%{class: :timer, timer: %{operation: :cancel}}), do: :timer_cancel
  defp kind(item), do: item.class

  defp insert(schedule, %{kind: :timer_cancel}), do: {:ok, schedule, nil}

  defp insert(schedule, item) do
    tail = List.last(schedule.queue)

    superseded =
      if tail && item.supersedable && tail.supersedable &&
           Map.take(tail, [:producer, :class, :source, :target, :name]) ==
             Map.take(item, [:producer, :class, :source, :target, :name]),
         do: tail,
         else: nil

    next = if superseded, do: %{schedule | queue: Enum.drop(schedule.queue, -1)}, else: schedule

    if within?(%{next | queue: next.queue ++ [item]}),
      do: {:ok, next, superseded},
      else: {:error, :overload}
  end

  defp within?(schedule),
    do:
      depth(schedule) <= 256 and
        Enum.all?(counts(schedule), fn {class, count} -> count <= Map.fetch!(@limits, class) end)

  defp work(schedule),
    do:
      schedule.queue ++ schedule.reserved ++ if(schedule.active, do: [schedule.active], else: [])

  defp depth(schedule), do: length(work(schedule))

  defp counts(schedule),
    do:
      Enum.reduce(
        work(schedule),
        Map.new(@classes, &{&1, 0}),
        &Map.update!(&2, &1.class, fn count -> count + 1 end)
      )

  defp sample(schedule), do: %{schedule | maximum: max(schedule.maximum, depth(schedule))}
  defp same_root?(a, b), do: a.root == b.root and a.generation == b.generation
  defp contains?(a, b), do: same_root?(a, b) and Enum.take(b.path, length(a.path)) == a.path

  defp keys?(value, keys),
    do: is_map(value) and not is_struct(value) and Enum.sort(Map.keys(value)) == Enum.sort(keys)

  defp bounded_map?(value, maximum),
    do: is_map(value) and not is_struct(value) and map_size(value) <= maximum

  defp subset?(values, allowed),
    do:
      is_list(values) and length(values) <= length(allowed) and Enum.uniq(values) == values and
        Enum.all?(values, &(&1 in allowed))
end
