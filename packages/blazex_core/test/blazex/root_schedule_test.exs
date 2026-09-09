defmodule BlazeX.RootScheduleTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{LocalView, RootPort, RootSchedule, ScheduledView}

  defmodule Component do
    use BlazeX.Component,
      role: :root,
      schema: [props: [{"count", [type: :integer, default: 0]}], slots: []]

    def mount(_), do: {:state, 0}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  def root, do: %{root: "r", path: [], generation: 1}

  def spec,
    do: %{
      root: "r",
      instance: "i",
      owner: "o",
      component: Component,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 5000
    }

  def policy do
    %{
      producers: %{
        "ui" => %{
          component: "root",
          classes: [:event, :update, :message, :timer],
          routes: [:self, :child, :parent, :root],
          supersedable: [:event, :update]
        }
      },
      events: %{increment: {:record, [{"delta", {:integer, 1, 9}}]}},
      messages: %{"root" => %{"tick" => {:record, [{"delta", {:integer, 1, 9}}]}}},
      components: %{"root" => [:self, :child, :parent, :root]}
    }
  end

  def candidate(correlation, count \\ 0) do
    identity = %{root() | generation: correlation.generation}

    RootPort.candidate(
      correlation,
      %{
        components: [
          %{
            identity: identity,
            role: :root,
            public_id: "root",
            schema_digest: String.duplicate("a", 64),
            state: {:present, count}
          }
        ]
      },
      String.duplicate("b", 64),
      :private
    )
  end

  def accepted do
    {:ok, correlation} = RootPort.correlation(spec(), 1, 1, 1, :mount)
    {:ok, value} = candidate(correlation)
    value
  end

  def envelope(sequence \\ 1, changes \\ %{}) do
    Map.merge(
      %{
        class: :event,
        producer: "ui",
        sequence: sequence,
        generation: 1,
        revision: 1,
        source: root(),
        target: root(),
        route: :self,
        name: :increment,
        payload: %{"delta" => 1},
        supersedable: false,
        timer: :none
      },
      changes
    )
  end

  test "policy and typed ingress are closed and schema checked" do
    assert {:ok, _} = RootSchedule.new(policy())

    for bad <- [
          Map.put(policy(), :extra, true),
          put_in(policy(), [:producers, "ui", :classes], [:unknown]),
          put_in(policy(), [:messages, "root", "tick"], {:callable, 1})
        ] do
      assert {:error, :invalid_policy} = RootSchedule.new(bad)
    end

    {:ok, schedule} = RootSchedule.new(policy())

    for changes <- [
          %{producer: "unknown"},
          %{payload: %{"delta" => "wrong"}},
          %{payload: self()},
          %{revision: 0},
          %{generation: 2},
          %{source: %{root() | root: "other"}},
          %{name: :unknown},
          %{timer: %{id: "injected"}},
          %{extra: :value}
        ] do
      assert {:error, :invalid_ingress, rejected} =
               RootSchedule.admit(schedule, envelope(1, changes), accepted(), spec())

      assert rejected.queue == [] and rejected.producers == %{}
    end
  end

  test "256 bound includes active and reserved work and rejects overload before mutation" do
    {:ok, empty} = RootSchedule.new(policy())

    full =
      Enum.reduce(1..256, empty, fn sequence, schedule ->
        assert {:ok, _, nil, next} =
                 RootSchedule.admit(schedule, envelope(sequence), accepted(), spec())

        assert RootSchedule.metrics(next).depth <= 256
        next
      end)

    assert RootSchedule.metrics(full).maximum == 256

    assert {:error, :overload, rejected} =
             RootSchedule.admit(full, envelope(257), accepted(), spec())

    assert rejected.producers == full.producers and rejected.queue == full.queue
    {:ok, first, selected} = RootSchedule.select(full)
    assert first.receipt == 1 and RootSchedule.metrics(selected).depth == 256
    assert {:error, :overload} = RootSchedule.reserve(selected, [first])

    assert {:ok, next, nil, _} =
             RootSchedule.admit(RootSchedule.finish(selected), envelope(257), accepted(), spec())

    assert next.receipt == 257
  end

  test "coalescing only replaces an equivalent opted-in queued tail" do
    {:ok, empty} = RootSchedule.new(policy())

    {:ok, first, nil, schedule} =
      RootSchedule.admit(empty, envelope(1, %{supersedable: true}), accepted(), spec())

    {:ok, second, ^first, schedule} =
      RootSchedule.admit(schedule, envelope(2, %{supersedable: true}), accepted(), spec())

    assert Enum.map(schedule.queue, & &1.receipt) == [second.receipt]

    {:ok, _, nil, schedule} =
      RootSchedule.admit(
        schedule,
        envelope(3, %{class: :message, name: "tick"}),
        accepted(),
        spec()
      )

    {:ok, _, nil, schedule} =
      RootSchedule.admit(schedule, envelope(4, %{supersedable: true}), accepted(), spec())

    assert Enum.map(schedule.queue, & &1.receipt) == [2, 3, 4]
    assert schedule.coalesced == 1
  end

  test "producer sequence and dispatch fingerprints reject replay and removed generations" do
    {:ok, empty} = RootSchedule.new(policy())
    {:ok, item, nil, schedule} = RootSchedule.admit(empty, envelope(), accepted(), spec())

    assert {:error, :stale_sequence, _} =
             RootSchedule.admit(schedule, envelope(), accepted(), spec())

    assert {:error, :stale_sequence, _} =
             RootSchedule.admit(schedule, envelope(3), accepted(), spec())

    assert RootSchedule.valid_dispatch?(item, put_in(accepted(), [:correlation, :revision], 2))
    refute RootSchedule.valid_dispatch?(item, put_in(accepted(), [:correlation, :generation], 2))
    refute RootSchedule.valid_dispatch?(item, put_in(accepted(), [:state, :components], []))

    changed =
      update_in(
        accepted(),
        [:state, :components],
        &Enum.map(&1, fn r -> %{r | schema_digest: "changed"} end)
      )

    refute RootSchedule.valid_dispatch?(item, changed)
  end

  test "per-class update bound is lower than total and timer intents are bounded" do
    {:ok, empty} = RootSchedule.new(policy())
    update = %{class: :update, name: "props", payload: %{props: %{}, slots: %{}}}

    full =
      Enum.reduce(1..64, empty, fn n, q ->
        {:ok, _, nil, q} = RootSchedule.admit(q, envelope(n, update), accepted(), spec())
        q
      end)

    assert {:error, :overload, _} =
             RootSchedule.admit(full, envelope(65, update), accepted(), spec())

    timer = %{
      class: :timer,
      name: "tick",
      timer: %{operation: :start, id: "clock", delay: 10, interval: 20}
    }

    assert {:ok, %{kind: :timer_start}, nil, _} =
             RootSchedule.admit(empty, envelope(1, timer), accepted(), spec())

    assert {:error, :invalid_ingress, _} =
             RootSchedule.admit(
               empty,
               envelope(1, put_in(timer, [:timer, :delay], 0)),
               accepted(),
               spec()
             )
  end

  defmodule Ports do
    def prepare(_config, request, _old),
      do: BlazeX.RootScheduleTest.candidate(request.correlation)

    def admit(_config, _work, _accepted), do: :ok

    def prepare_scheduled(config, request, old) do
      send(config, {:dispatch, request.work.receipt})
      {:present, count} = hd(old.state.components).state
      {:ok, candidate} = BlazeX.RootScheduleTest.candidate(request.correlation, count + 1)
      {:ok, candidate, []}
    end

    def cleanup(_, _, _), do: :ok
    def cleanup_removed(_, _, _), do: :ok

    def submit(config, correlation, _candidate),
      do:
        (
          send(config, {:submitted, correlation})
          :ok
        )

    def cancel(_, _), do: :ok

    def notify(config, record),
      do:
        (
          send(config, {:observation, record})
          :ok
        )
  end

  test "opt-in ingress waits behind renderer commit and emits one ordered outcome per receipt" do
    supervisor = start_supervised!(LocalView.Supervisor)
    ports = %{evaluator: {Ports, self()}, renderer: {Ports, self()}, host: {Ports, self()}}
    {:ok, handle} = ScheduledView.start(supervisor, spec(), ports, policy())
    assert_receive {:submitted, mount}

    assert :ok =
             LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})

    assert {:error, :scheduled_ingress_required} = LocalView.update(supervisor, handle, 1, %{})
    assert {:ok, %{receipt: 1}} = ScheduledView.event(supervisor, handle, envelope(1))
    assert_receive {:dispatch, 1}
    assert_receive {:submitted, first}
    assert {:ok, %{receipt: 2}} = ScheduledView.event(supervisor, handle, envelope(2))
    refute_receive {:dispatch, 2}
    assert {:ok, before} = LocalView.inspect_root(supervisor, handle)
    assert before.scheduling.depth == 2

    assert :ok =
             LocalView.acknowledge(supervisor, handle, %{correlation: first, result: :committed})

    assert_receive {:observation,
                    %{event: :work_outcome, work: %{receipt: 1}, result: :committed}}

    assert_receive {:dispatch, 2}
    assert_receive {:submitted, second}

    assert {:error, :renderer_rejected} =
             LocalView.acknowledge(supervisor, handle, %{
               correlation: second,
               result: :rolled_back
             })

    assert_receive {:observation, %{event: :work_outcome, work: %{receipt: 2}, result: :rejected}}
    assert {:ok, after_reject} = LocalView.inspect_root(supervisor, handle)
    assert after_reject.accepted.correlation == first
    assert after_reject.scheduling.depth == 0
    refute_receive {:observation, %{event: :work_outcome}}
  end
end

defmodule BlazeX.ScheduledIntentsTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{LocalView, ScheduledView}
  alias BlazeX.RootScheduleTest, as: F

  defmodule Ports do
    def prepare({pid, _}, request, old),
      do: BlazeX.RootScheduleTest.Ports.prepare(pid, request, old)

    def admit(_, _, _), do: :ok

    def prepare_scheduled({pid, mode}, request, old) do
      {:ok, candidate, []} = BlazeX.RootScheduleTest.Ports.prepare_scheduled(pid, request, old)

      actions =
        case {request.work.receipt, mode} do
          {1, :message} ->
            [
              {:message, "self",
               %{target: BlazeX.RootScheduleTest.root(), name: "tick", payload: %{"delta" => 1}}}
            ]

          {1, :timer} ->
            [
              {:timer, "clock",
               %{
                 operation: :start,
                 route: :self,
                 target: BlazeX.RootScheduleTest.root(),
                 name: "tick",
                 payload: %{"delta" => 1},
                 delay: 10,
                 interval: nil
               }}
            ]

          {1, :effect} ->
            [{:effect, "provider", %{}}]

          _ ->
            []
        end

      {:ok, candidate, [%{source: BlazeX.RootScheduleTest.root(), actions: actions}]}
    end

    def cleanup(_, _, _), do: :ok
    def cleanup_removed(_, _, _), do: :ok

    def submit({pid, _}, correlation, candidate),
      do: BlazeX.RootScheduleTest.Ports.submit(pid, correlation, candidate)

    def cancel(_, _), do: :ok
    def notify({pid, _}, record), do: BlazeX.RootScheduleTest.Ports.notify(pid, record)
  end

  defp start(mode) do
    supervisor = start_supervised!({LocalView.Supervisor, []}, id: mode)

    ports = %{
      evaluator: {Ports, {self(), mode}},
      renderer: {Ports, {self(), mode}},
      host: {Ports, {self(), mode}}
    }

    {:ok, handle} = ScheduledView.start(supervisor, F.spec(), ports, F.policy())
    assert_receive {:submitted, mount}
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    {supervisor, handle, mount}
  end

  test "candidate-only messages and timers start only after commit" do
    for mode <- [:message, :timer] do
      {supervisor, handle, _} = start(mode)
      {:ok, _} = ScheduledView.event(supervisor, handle, F.envelope())
      assert_receive {:dispatch, 1}
      assert_receive {:submitted, event}
      refute_receive {:dispatch, 2}, 30
      {:ok, pending} = LocalView.inspect_root(supervisor, handle)
      assert pending.timers.active == 0
      assert pending.scheduling.reserved == if(mode == :message, do: 1, else: 0)
      :ok = LocalView.acknowledge(supervisor, handle, %{correlation: event, result: :committed})
      assert_receive {:dispatch, 2}
      assert_receive {:submitted, followup}

      :ok =
        LocalView.acknowledge(supervisor, handle, %{correlation: followup, result: :committed})

      {:ok, done} = LocalView.inspect_root(supervisor, handle)
      assert done.scheduling.depth == 0 and done.timers.active == 0
    end
  end

  test "rejected candidates discard every action and prohibited effects never reach renderer" do
    for mode <- [:message, :timer, :effect] do
      {supervisor, handle, mount} = start(mode)
      {:ok, _} = ScheduledView.event(supervisor, handle, F.envelope())
      assert_receive {:dispatch, 1}

      if mode == :effect do
        refute_receive {:submitted, _}, 30
      else
        assert_receive {:submitted, event}

        assert {:error, :renderer_rejected} =
                 LocalView.acknowledge(supervisor, handle, %{
                   correlation: event,
                   result: :rejected
                 })
      end

      refute_receive {:dispatch, 2}, 30
      {:ok, done} = LocalView.inspect_root(supervisor, handle)
      assert done.accepted.correlation == mount
      assert done.scheduling.depth == 0 and done.timers.active == 0
    end
  end

  test "replacement cancels queued work and rejects old acknowledgements and generation" do
    {supervisor, handle, _} = start(:message)
    {:ok, _} = ScheduledView.event(supervisor, handle, F.envelope())
    assert_receive {:submitted, event}
    {:ok, _} = ScheduledView.event(supervisor, handle, F.envelope(2))
    assert {:ok, replacement} = LocalView.replace(supervisor, handle, 1, F.spec())
    assert_receive {:submitted, ^replacement}
    assert replacement.generation == 2

    assert {:error, :stale} =
             LocalView.acknowledge(supervisor, handle, %{correlation: event, result: :committed})

    :ok =
      LocalView.acknowledge(supervisor, handle, %{correlation: replacement, result: :committed})

    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.scheduling.depth == 0 and snapshot.timers.active == 0
    assert {:error, :invalid_ingress} = ScheduledView.event(supervisor, handle, F.envelope(3))
  end

  test "runtime loss and shutdown drop queued and candidate-only work" do
    for mode <- [:message, :timer] do
      {supervisor, handle, _} = start(mode)
      {:ok, _} = ScheduledView.event(supervisor, handle, F.envelope())
      assert_receive {:submitted, event}
      {:ok, _} = ScheduledView.event(supervisor, handle, F.envelope(2))

      if mode == :message do
        assert {:error, _} = ScheduledView.runtime_loss(supervisor, handle)
      else
        {:ok, disposal} = LocalView.stop(supervisor, handle)
        assert_receive {:submitted, ^disposal}

        :ok =
          LocalView.acknowledge(supervisor, handle, %{correlation: disposal, result: :committed})
      end

      assert {:error, _} =
               LocalView.acknowledge(supervisor, handle, %{correlation: event, result: :committed})

      {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
      assert snapshot.status in [:failed, :disposed]
      assert snapshot.scheduling.depth == 0 and snapshot.timers.active == 0
    end
  end
end

defmodule BlazeX.RootTimersTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{LocalView, RootSchedule, RootTimers, ScheduledView, SchedulingIntents}
  alias BlazeX.RootScheduleTest, as: F

  defp timer(sequence \\ 1, changes \\ %{}) do
    F.envelope(
      sequence,
      Map.merge(
        %{
          class: :timer,
          name: "tick",
          timer: %{operation: :start, id: "clock", delay: 10, interval: nil}
        },
        changes
      )
    )
  end

  test "one-shot tokens reject forged, duplicate and canceled wakes" do
    {:ok, item} = RootSchedule.normalize(F.policy(), timer(), F.accepted(), F.spec())
    {:ok, timers} = RootTimers.install(%RootTimers{}, item)
    assert {:error, _} = RootTimers.install(timers, item)

    assert {:error, _} =
             RootTimers.wake(timers, RootTimers.key(item), 1, make_ref(), F.accepted())

    assert_receive {:owned_tick, key, epoch, token}
    assert {:ok, tick, firing} = RootTimers.wake(timers, key, epoch, token, F.accepted())
    assert RootTimers.valid_tick?(firing, tick)
    assert {:error, _} = RootTimers.wake(firing, key, epoch, token, F.accepted())
    done = RootTimers.finish(firing, tick)
    assert RootTimers.inventory(done).active == 0
    assert RootTimers.inventory(done).completed == 1
    refute RootTimers.valid_tick?(done, tick)
    {:ok, restarted} = RootTimers.install(done, item)
    assert {:error, _} = RootTimers.wake(restarted, key, epoch, token, F.accepted())
    assert RootTimers.inventory(RootTimers.cancel_all(restarted)).canceled == 1
  end

  test "repeating timers wait for the previous tick outcome and owner replacement cancels them" do
    {:ok, item} =
      RootSchedule.normalize(
        F.policy(),
        timer(1, %{timer: %{operation: :start, id: "clock", delay: 10, interval: 10}}),
        F.accepted(),
        F.spec()
      )

    {:ok, timers} = RootTimers.install(%RootTimers{}, item)
    assert_receive {:owned_tick, key, epoch, token}
    {:ok, tick, timers} = RootTimers.wake(timers, key, epoch, token, F.accepted())
    refute_receive {:owned_tick, _, _, _}, 30
    timers = RootTimers.finish(timers, tick)
    assert_receive {:owned_tick, ^key, ^epoch, second_token}
    refute second_token == token
    replaced = put_in(F.accepted(), [:correlation, :generation], 2)
    timers = RootTimers.prune(timers, replaced)
    assert RootTimers.inventory(timers).active == 0
    assert {:error, _} = RootTimers.wake(timers, key, epoch, second_token, replaced)
  end

  test "timer registry is bounded and intent validation rejects non-local actions" do
    {:ok, item} = RootSchedule.normalize(F.policy(), timer(), F.accepted(), F.spec())

    timers =
      Enum.reduce(1..32, %RootTimers{}, fn n, timers ->
        {:ok, next} = RootTimers.install(timers, put_in(item, [:timer, :id], "clock_#{n}"))
        next
      end)

    assert {:error, _} = RootTimers.install(timers, item)
    assert RootTimers.inventory(RootTimers.cancel_all(timers)).canceled == 32
    message = {:message, "self", %{target: F.root(), name: "tick", payload: %{"delta" => 1}}}

    assert {:ok, [%{kind: :message, origin: :component}]} =
             SchedulingIntents.normalize(
               F.policy(),
               [%{source: F.root(), actions: [message]}],
               F.accepted(),
               F.spec()
             )

    for action <- [
          {:effect, "fetch", %{}},
          {:command, "remote", %{}},
          {:release, "resource", %{}},
          {:message, "self", %{target: F.root(), name: "tick", payload: self()}}
        ] do
      assert {:error, :invalid_intent} =
               SchedulingIntents.normalize(
                 F.policy(),
                 [%{source: F.root(), actions: [action]}],
                 F.accepted(),
                 F.spec()
               )
    end
  end

  test "cancel ingress bypasses a full application queue without increasing its depth" do
    {:ok, queue} = RootSchedule.new(F.policy())

    full =
      Enum.reduce(1..256, queue, fn n, q ->
        {:ok, _, _, q} = RootSchedule.admit(q, F.envelope(n), F.accepted(), F.spec())
        q
      end)

    assert {:ok, %{kind: :timer_cancel, receipt: 257}, nil, next} =
             RootSchedule.admit(
               full,
               timer(257, %{timer: %{operation: :cancel, id: "clock"}}),
               F.accepted(),
               F.spec()
             )

    assert next.queue == full.queue
    assert RootSchedule.metrics(next).depth == 256
  end

  test "explicit cancellation aborts an in-flight timer tick and rejects its late acknowledgement" do
    supervisor = start_supervised!(LocalView.Supervisor)
    ports = %{evaluator: {F.Ports, self()}, renderer: {F.Ports, self()}, host: {F.Ports, self()}}
    {:ok, handle} = ScheduledView.start(supervisor, F.spec(), ports, F.policy())
    assert_receive {:submitted, mount}
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    assert {:ok, %{receipt: 1}} = ScheduledView.timer(supervisor, handle, timer())

    assert_receive {:observation,
                    %{event: :work_outcome, work: %{receipt: 1}, result: :committed}}

    assert_receive {:dispatch, 2}
    assert_receive {:submitted, tick}

    assert {:ok, %{receipt: 3}} =
             ScheduledView.timer(
               supervisor,
               handle,
               timer(2, %{timer: %{operation: :cancel, id: "clock"}})
             )

    assert_receive {:observation, %{event: :work_outcome, work: %{receipt: 2}, result: :canceled}}

    assert_receive {:observation,
                    %{event: :work_outcome, work: %{receipt: 3}, result: :committed}}

    assert {:error, :stale} =
             LocalView.acknowledge(supervisor, handle, %{correlation: tick, result: :committed})

    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.accepted.correlation == mount
    assert snapshot.timers.active == 0 and snapshot.scheduling.depth == 0
    refute_receive {:observation, %{event: :work_outcome}}
  end
end
