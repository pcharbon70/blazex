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

    def release(_, _), do: :released

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
end
