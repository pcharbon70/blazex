defmodule BlazeX.ActionTest do
  use ExUnit.Case, async: true

  alias BlazeX.Component.{
    Action,
    ActionLedger,
    ActionManifest,
    ActionView,
    LocalView,
    RootPort,
    RootSchedule,
    ScheduledView
  }

  defmodule Root do
    use BlazeX.Component,
      role: :root,
      capabilities: ["ui.storage"],
      schema: [props: [], slots: []]

    def mount(_), do: {:state, 0}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  def owner, do: %{root: "r", path: [], generation: 1}

  def spec,
    do: %{
      root: "r",
      instance: "i",
      owner: "runtime",
      component: Root,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: ["ui.storage"],
      fallback: :none,
      timeout_ms: 5000
    }

  def manifest do
    schema = {:record, [{"value", :integer}]}

    declaration = %{
      schema_version: "1.0.0",
      request: schema,
      result: schema,
      error: {:record, [{"code", :string}]}
    }

    %{
      effects: %{
        "read" =>
          Map.merge(declaration, %{
            capability: "ui.storage",
            operation: "get",
            fallback: :deny,
            lease_kind: nil,
            lease_limit: 0
          })
      },
      commands: %{"save" => declaration},
      owners: %{"root" => %{effects: ["read"], commands: ["save"], transfers: [:self, :child]}}
    }
  end

  def action(n \\ 1, body \\ %{}) do
    {:ok, action} =
      Action.new(
        :effect_request,
        "read_#{n}",
        n,
        owner(),
        Map.merge(
          %{
            declaration: "read",
            payload: %{"value" => 1},
            timeout_ms: 5000,
            idempotency_key: "request_#{n}",
            fallback: :deny
          },
          body
        )
      )

    action
  end

  def candidate(correlation, n \\ 0),
    do:
      RootPort.candidate(
        correlation,
        %{
          components: [
            %{
              identity: owner(),
              role: :root,
              public_id: "root",
              schema_digest: String.duplicate("a", 64),
              state: {:present, n}
            }
          ]
        },
        String.duplicate("b", 64),
        :private
      )

  def accepted do
    {:ok, corr} = RootPort.correlation(spec(), 1, 1, 1, :mount)
    {:ok, candidate} = candidate(corr)
    candidate
  end

  def policy,
    do: %{
      producers: %{
        "ui" => %{component: "root", classes: [:event], routes: [:self], supersedable: []}
      },
      events: %{increment: {:record, [{"value", :integer}]}},
      messages: %{},
      components: %{"root" => [:self]}
    }

  def envelope(n \\ 1, revision \\ 1),
    do: %{
      class: :event,
      producer: "ui",
      sequence: n,
      generation: 1,
      revision: revision,
      source: owner(),
      target: owner(),
      route: :self,
      name: :increment,
      payload: %{"value" => 1},
      supersedable: false,
      timer: :none
    }

  defmodule Port do
    def select(_, _), do: {:granted, "test"}

    def submit(pid, %{action: _} = entry),
      do:
        (
          send(pid, {:effect, entry})
          :accepted
        )

    def submit(pid, correlation, candidate),
      do:
        (
          send(pid, {:renderer, correlation, candidate})
          :ok
        )

    def cancel(pid, entry),
      do:
        (
          send(pid, {:cancel, entry})
          :ok
        )

    def release(pid, lease) do
      send(pid, {:released, lease})
      :released
    end

    def notify(pid, record),
      do:
        (
          send(pid, {:host, record})
          :ok
        )

    def prepare(_, request, _), do: BlazeX.ActionTest.candidate(request.correlation)

    def prepare_scheduled(_, request, old) do
      {:present, n} = hd(old.state.components).state
      {:ok, candidate} = BlazeX.ActionTest.candidate(request.correlation, n + 1)

      actions =
        if request.work.kind == :action_result,
          do: [],
          else: [BlazeX.ActionTest.action(request.correlation.sequence)]

      {:ok, candidate, [%{source: BlazeX.ActionTest.owner(), actions: actions}]}
    end

    def admit(_, _, _), do: :ok
    def admit_action(_, _, _), do: :ok
    def cleanup(_, _, _), do: :ok
    def cleanup_removed(_, _, _), do: :ok
  end

  test "action/result constructors and manifest reject open schemas, handles and authority fields" do
    assert Action.valid?(action())
    assert :ok = ActionManifest.validate(manifest())

    for bad <- [
          Map.put(action(), :extra, true),
          put_in(action(), [:body, :payload], self()),
          put_in(action(), [:body, :payload], %{"authorization" => true}),
          put_in(action(), [:body, :timeout_ms], 0)
        ] do
      refute Action.valid?(bad)
    end

    refute Action.valid?(%{action() | kind: :unknown})

    assert {:error, :invalid_manifest} =
             ActionManifest.validate(Map.put(manifest(), :transport, "server"))

    assert {:ok, metadata} = ActionManifest.metadata(manifest())
    assert metadata.command_trust == :untrusted_client
    correlation = Action.correlation(action(), spec())
    assert {:ok, result} = Action.result(correlation, :completed, %{"value" => 2})
    assert Action.result?(result)
    refute Action.result?(Map.put(result, :extra, true))
  end

  test "whole batches validate atomically and reserve at most 128 pending requests" do
    groups = fn n -> [%{source: owner(), actions: [action(n)]}] end

    ledger =
      Enum.reduce(1..128, %ActionLedger{}, fn n, ledger ->
        {:ok, plan} =
          ActionLedger.prepare(ledger, groups.(n), accepted(), spec(), manifest(), {Port, self()})

        ledger = ActionLedger.install(ledger, hd(plan.actions).request)
        %{ledger | sequences: plan.sequences}
      end)

    assert map_size(ledger.pending) == 128

    assert {:error, _} =
             ActionLedger.prepare(
               ledger,
               groups.(129),
               accepted(),
               spec(),
               manifest(),
               {Port, self()}
             )

    assert {:error, _} =
             ActionLedger.prepare(
               %ActionLedger{},
               [%{source: owner(), actions: [action(), action()]}],
               accepted(),
               spec(),
               manifest(),
               {Port, self()}
             )

    assert {:error, _} =
             ActionLedger.prepare(
               %ActionLedger{},
               [%{source: owner(), actions: [{:effect, "old", %{}}]}],
               accepted(),
               spec(),
               manifest(),
               {Port, self()}
             )
  end

  test "result reservation is inside the 256 work bound and cannot be displaced" do
    {:ok, schedule} = RootSchedule.new(policy())
    {:ok, schedule} = RootSchedule.results(schedule, 128)

    schedule =
      Enum.reduce(1..128, schedule, fn n, q ->
        {:ok, _, _, q} = RootSchedule.admit(q, envelope(n), accepted(), spec())
        q
      end)

    assert RootSchedule.metrics(schedule).depth == 256

    assert {:error, :overload, _} =
             RootSchedule.admit(schedule, envelope(129), accepted(), spec())
  end

  test "provider submission waits for commit and terminal results take a reserved FIFO slot" do
    supervisor = start_supervised!(LocalView.Supervisor)
    ports = %{evaluator: {Port, self()}, renderer: {Port, self()}, host: {Port, self()}}

    {:ok, handle} =
      ActionView.start(supervisor, spec(), ports, policy(), manifest(), {Port, self()})

    assert_receive {:renderer, mount, _}
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    {:ok, _} = ScheduledView.event(supervisor, handle, envelope())
    assert_receive {:renderer, event, _}
    refute_receive {:effect, _}, 30
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: event, result: :committed})
    assert_receive {:effect, request}
    {:ok, pending} = LocalView.inspect_root(supervisor, handle)
    assert pending.actions.pending == 1 and pending.scheduling.depth == 1
    {:ok, result} = Action.result(request.correlation, :completed, %{"value" => 2})
    :ok = ActionView.result(supervisor, handle, result)
    assert_receive {:renderer, response, _}
    assert {:error, :invalid_or_stale_result} = ActionView.result(supervisor, handle, result)
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: response, result: :committed})
    {:ok, final} = LocalView.inspect_root(supervisor, handle)
    assert final.actions.pending == 0 and final.scheduling.depth == 0
    refute_receive {:effect, _}, 30
  end

  defmodule SelectionPort do
    def select({_pid, :deny}, _), do: :denied
    def select({_pid, :fallback}, _), do: {:fallback, "fallback-provider"}
    def select(_, _), do: {:granted, "test"}

    def submit({pid, mode}, entry),
      do:
        (
          send(pid, {:effect, entry})
          if(mode == :disconnect, do: :disconnected, else: :accepted)
        )

    def cancel({pid, _}, entry),
      do:
        (
          send(pid, {:cancel, entry})
          :ok
        )

    def release(_, _), do: :released
  end

  test "denial fallback disconnection failure timeout and cancellation are bounded typed outcomes" do
    alias BlazeX.Component.ActionRuntime

    for mode <- [:deny, :fallback, :disconnect, :accept] do
      manifest =
        if mode == :fallback,
          do: put_in(manifest(), [:effects, "read", :fallback], :component),
          else: manifest()

      action =
        action(1, %{timeout_ms: 10, fallback: if(mode == :fallback, do: :component, else: :deny)})

      {:ok, runtime} =
        ActionRuntime.new(%{manifest: manifest, port: {SelectionPort, {self(), mode}}})

      {:ok, plan} =
        ActionRuntime.prepare(
          runtime,
          [%{source: owner(), actions: [action]}],
          accepted(),
          spec(),
          policy(),
          {Port, self()}
        )

      {runtime, work} = ActionRuntime.commit(runtime, plan, accepted())

      if mode in [:deny, :disconnect] do
        assert length(work) == 1
        assert hd(work).payload.status == if(mode == :deny, do: :denied, else: :disconnected)
        assert ActionRuntime.pending(runtime) == 0
      else
        assert work == [] and ActionRuntime.pending(runtime) == 1
        assert_receive {:action_timeout, correlation, token}, 1000

        assert {:ok, runtime, work} =
                 ActionRuntime.timeout(runtime, correlation, token, accepted())

        assert work.payload.status == :timed_out

        assert {:error, :stale_timeout} =
                 ActionRuntime.timeout(runtime, correlation, token, accepted())

        assert ActionRuntime.pending(runtime) == 0
      end
    end

    {:ok, runtime} = ActionRuntime.new(%{manifest: manifest(), port: {Port, self()}})

    {:ok, plan} =
      ActionRuntime.prepare(
        runtime,
        [%{source: owner(), actions: [action()]}],
        accepted(),
        spec(),
        policy(),
        {Port, self()}
      )

    {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())
    correlation = Action.correlation(action(), spec())
    {:ok, bad} = Action.result(%{correlation | id: "wrong"}, :failed, %{"code" => "denied"})
    assert {:error, _} = ActionRuntime.complete(runtime, bad, accepted())
    {:ok, cancel} = Action.new(:effect_cancel, "cancel", 2, owner(), %{correlation: correlation})

    {:ok, plan} =
      ActionRuntime.prepare(
        runtime,
        [%{source: owner(), actions: [cancel]}],
        accepted(),
        spec(),
        policy(),
        {Port, self()}
      )

    {runtime, [work]} = ActionRuntime.commit(runtime, plan, accepted())
    assert work.payload.status == :canceled

    assert {:error, _} =
             ActionRuntime.prepare(
               runtime,
               [%{source: owner(), actions: [action()]}],
               accepted(),
               spec(),
               policy(),
               {Port, self()}
             )
  end

  test "renderer rejection never submits candidate requests or consumes action sequence" do
    supervisor = start_supervised!(LocalView.Supervisor)
    ports = %{evaluator: {Port, self()}, renderer: {Port, self()}, host: {Port, self()}}

    {:ok, handle} =
      ActionView.start(supervisor, spec(), ports, policy(), manifest(), {Port, self()})

    assert_receive {:renderer, mount, _}
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    {:ok, _} = ScheduledView.event(supervisor, handle, envelope())
    assert_receive {:renderer, event, _}

    {:error, :renderer_rejected} =
      LocalView.acknowledge(supervisor, handle, %{correlation: event, result: :rejected})

    refute_receive {:effect, _}, 30
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.actions.pending == 0 and snapshot.scheduling.depth == 0
  end

  defp lease_manifest do
    manifest()
    |> put_in([:effects, "read", :lease_kind], "subscription")
    |> put_in([:effects, "read", :lease_limit], 16)
  end

  defp action_plan(runtime, actions, candidate \\ accepted()) do
    BlazeX.Component.ActionRuntime.prepare(
      runtime,
      [%{source: owner(), actions: actions}],
      candidate,
      spec(),
      policy(),
      {Port, self()}
    )
  end

  test "512 leases include pending acquisition reservations and reject the 513th atomically" do
    alias BlazeX.Component.ActionRuntime
    {:ok, runtime} = ActionRuntime.new(%{manifest: lease_manifest(), port: {Port, self()}})

    {runtime, samples} =
      Enum.reduce(1..32, {runtime, []}, fn n, {runtime, samples} ->
        {:ok, plan} = action_plan(runtime, [action(n)])
        {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())
        ids = Enum.map(1..16, &"lease_#{n}_#{&1}")

        {:ok, result} =
          Action.result(Action.correlation(action(n), spec()), :completed, %{"value" => n}, ids)

        {:ok, runtime, work} = ActionRuntime.complete(runtime, result, accepted())
        assert length(work.payload.leases) == 16
        {runtime, samples ++ [ActionLedger.lease_depth(runtime.ledger)]}
      end)

    assert samples == Enum.to_list(16..512//16)
    assert map_size(runtime.ledger.leases) == 512
    assert {:error, :invalid_action_batch} = action_plan(runtime, [action(33)])
    closed = ActionRuntime.close(runtime, :shutdown)
    assert closed.ledger.leases == %{} and closed.ledger.totals.released == 512
    assert length(closed.ledger.history) == 128
  end

  test "leases transfer only on declared routes and stale acquisition references never release reused IDs" do
    alias BlazeX.Component.ActionRuntime
    {:ok, runtime} = ActionRuntime.new(%{manifest: lease_manifest(), port: {Port, self()}})
    {:ok, plan} = action_plan(runtime, [action()])
    {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())

    {:ok, result} =
      Action.result(Action.correlation(action(), spec()), :completed, %{"value" => 1}, ["lease"])

    {:ok, runtime, work} = ActionRuntime.complete(runtime, result, accepted())
    [reference] = work.payload.leases

    transfer = fn n, target ->
      {:ok, a} =
        Action.new(:resource_transfer, "transfer_#{n}", n, owner(), %{
          lease: reference,
          target: target
        })

      a
    end

    assert {:error, _} = action_plan(runtime, [transfer.(2, %{owner() | root: "other"})])
    assert {:error, _} = action_plan(runtime, [transfer.(2, %{owner() | generation: 2})])
    assert {:error, _} = action_plan(runtime, [transfer.(2, owner()), transfer.(3, owner())])
    {:ok, plan} = action_plan(runtime, [transfer.(2, owner())])
    {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())
    assert runtime.ledger.leases["lease"].status == :transferred
    assert length(runtime.ledger.leases["lease"].transfer_history) == 1
    {:ok, release} = Action.new(:resource_release, "release", 3, owner(), %{lease: reference})
    {:ok, plan} = action_plan(runtime, [release])
    {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())
    assert_receive {:released, %{id: "lease", release_requested: true}}
    assert {:error, _} = action_plan(runtime, [%{release | sequence: 4}])
    {:ok, plan} = action_plan(runtime, [action(4)])
    {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())

    {:ok, result} =
      Action.result(Action.correlation(action(4), spec()), :completed, %{"value" => 2}, ["lease"])

    {:ok, runtime, _} = ActionRuntime.complete(runtime, result, accepted())
    assert {:error, _} = action_plan(runtime, [%{release | sequence: 5}])
    assert ActionRuntime.finish_result(runtime, work, false) == runtime
    closed = ActionRuntime.close(runtime, :replace)
    assert closed.ledger.sequences == runtime.ledger.sequences
    assert {:error, _} = ActionRuntime.complete(closed, result, accepted())
  end

  test "rejected result callbacks and removed owners release newly acquired resources" do
    alias BlazeX.Component.ActionRuntime
    {:ok, runtime} = ActionRuntime.new(%{manifest: lease_manifest(), port: {Port, self()}})
    {:ok, plan} = action_plan(runtime, [action()])
    {runtime, []} = ActionRuntime.commit(runtime, plan, accepted())

    {:ok, result} =
      Action.result(Action.correlation(action(), spec()), :completed, %{"value" => 1}, ["lease"])

    {:ok, runtime, work} = ActionRuntime.complete(runtime, result, accepted())
    assert ActionRuntime.finish_result(runtime, work, true) == runtime
    rejected = ActionRuntime.finish_result(runtime, work, false)
    assert rejected.ledger.leases == %{} and rejected.ledger.totals.released == 1
    removed = put_in(accepted(), [:state, :components], [])
    assert ActionRuntime.prune(runtime, removed).ledger.leases == %{}
  end

  test "commands remain untrusted and a provider denial preserves the accepted state" do
    alias BlazeX.Component.ActionRuntime

    body = %{
      declaration: "save",
      payload: %{"value" => 1},
      timeout_ms: 1000,
      idempotency_key: "save_1",
      optimistic_revision: 1,
      trust: :untrusted_client
    }

    {:ok, command} = Action.new(:command, "save_1", 1, owner(), body)

    for changes <- [
          %{trust: :authorized},
          %{transport: "server"},
          %{payload: %{"authorization" => true}},
          %{payload: %{"module" => "Server"}},
          %{payload: self()}
        ] do
      assert {:error, _} = Action.new(:command, "save_1", 1, owner(), Map.merge(body, changes))
    end

    {:ok, runtime} =
      ActionRuntime.new(%{manifest: manifest(), port: {SelectionPort, {self(), :deny}}})

    before = accepted()
    {:ok, plan} = action_plan(runtime, [command])
    {runtime, [work]} = ActionRuntime.commit(runtime, plan, before)
    assert work.payload.trust == :untrusted_client and work.payload.status == :denied
    assert runtime.ledger.pending == %{} and accepted() == before
    refute_receive {:effect, _}, 20
  end

  defmodule CrashPort do
    def select(_, _), do: {:granted, "crash"}

    def submit(pid, entry) do
      send(pid, {:attempted, entry})
      :erlang.exit(self(), :kill)
    end

    def cancel(pid, entry) do
      send(pid, {:crash_cancel, entry})
      :ok
    end

    def release(_, _), do: :released
  end

  test "guardian cancels the pre-submission checkpoint after coordinator death without replay" do
    supervisor = start_supervised!(LocalView.Supervisor)
    ports = %{evaluator: {Port, self()}, renderer: {Port, self()}, host: {Port, self()}}

    {:ok, handle} =
      ActionView.start(supervisor, spec(), ports, policy(), manifest(), {CrashPort, self()})

    assert_receive {:renderer, mount, _}
    :ok = LocalView.acknowledge(supervisor, handle, %{correlation: mount, result: :committed})
    {:ok, _} = ScheduledView.event(supervisor, handle, envelope())
    assert_receive {:renderer, event, _}

    assert {:error, :crashed} =
             LocalView.acknowledge(supervisor, handle, %{correlation: event, result: :committed})

    assert_receive {:attempted, entry}
    assert_receive {:crash_cancel, ^entry}
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.status == :failed and snapshot.actions.pending == 0
    assert snapshot.actions.totals.canceled == 1
    refute_receive {:attempted, _}, 20
  end

  test "batch release preserves bounded history and exact per-resource terminal states" do
    leases =
      Map.new(1..512, fn sequence ->
        id = "lease-#{sequence}"
        {id, %{id: id, acquisition: %{sequence: sequence}}}
      end)

    releases =
      leases
      |> Map.values()
      |> Enum.sort_by(& &1.acquisition.sequence)
      |> Enum.map(fn lease ->
        {lease, if(rem(lease.acquisition.sequence, 2) == 0, do: :released, else: :lost)}
      end)

    ledger = ActionLedger.released_many(%ActionLedger{leases: leases}, releases)
    assert ledger.leases == %{}
    assert ledger.totals == %{lost: 256, released: 256}
    assert length(ledger.history) == 128
    assert hd(ledger.history).correlation.id == "lease-385"
    assert List.last(ledger.history).correlation.id == "lease-512"
  end
end
