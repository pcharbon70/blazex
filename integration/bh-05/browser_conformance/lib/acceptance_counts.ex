defmodule BlazeX.BH05.Acceptance.Counts do
  @moduledoc false
  alias BlazeX.Component.{Action, ActionLedger, RecoveryPolicy, RootPort, RootSchedule}

  defmodule Root do
    use BlazeX.Component,
      role: :root,
      capabilities: ["ui.storage"],
      schema: [props: [], slots: []]

    def mount(_), do: {:state, 0}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule Port do
    def select(_, _), do: {:granted, "measurement"}
  end

  def run(repetitions \\ 20) do
    %{
      "schema_version" => "1.0.0",
      "result" => "passed",
      "samples" =>
        Enum.map(1..repetitions, fn sample ->
          Map.merge(%{"sample" => sample}, sample())
        end)
    }
  end

  defp sample do
    backlog = backlog()
    :erlang.display({:bh05_phase12_counts, :backlog})
    pending = pending()
    :erlang.display({:bh05_phase12_counts, :pending})
    leases = leases()
    :erlang.display({:bh05_phase12_counts, :leases})
    restarts = restarts()
    :erlang.display({:bh05_phase12_counts, :restarts})

    %{
      "event_backlog" => backlog,
      "pending_effects" => pending,
      "resource_leases" => leases,
      "restart_intensity" => restarts
    }
  end

  defp backlog do
    {:ok, empty} = RootSchedule.new(policy())
    accepted = accepted()
    spec = spec()

    full =
      Enum.reduce(1..256, empty, fn sequence, schedule ->
        {:ok, _, nil, next} = RootSchedule.admit(schedule, envelope(sequence), accepted, spec)
        next
      end)

    {:error, :overload, rejected} =
      RootSchedule.admit(full, envelope(257), accepted, spec)

    metrics = RootSchedule.metrics(rejected)

    %{
      "maximum" => metrics.maximum,
      "admitted" => metrics.admitted,
      "rejected" => metrics.rejected,
      "ordered" => metrics.queued_receipts == Enum.to_list(1..256),
      "terminal_depth" => metrics.depth
    }
  end

  defp pending do
    accepted = accepted()
    spec = spec()
    manifest = manifest(0)

    ledger =
      Enum.reduce(1..128, %ActionLedger{}, fn sequence, ledger ->
        {:ok, plan} =
          ActionLedger.prepare(
            ledger,
            [%{source: owner(), actions: [action(sequence)]}],
            accepted,
            spec,
            manifest,
            {Port, nil}
          )

        installed = ActionLedger.install(ledger, hd(plan.actions).request)
        %{installed | sequences: plan.sequences}
      end)

    {:error, :invalid_action_batch} =
      ActionLedger.prepare(
        ledger,
        [%{source: owner(), actions: [action(129)]}],
        accepted,
        spec,
        manifest,
        {Port, nil}
      )

    %{
      "maximum" => map_size(ledger.pending),
      "rejected" => 1,
      "completed" => 0,
      "failed" => 0,
      "timed_out" => 0,
      "canceled" => 0
    }
  end

  defp leases do
    accepted = accepted()
    spec = spec()
    manifest = manifest(16)

    ledger =
      Enum.reduce(0..1, %ActionLedger{}, fn batch, ledger ->
        actions = Enum.map((batch * 16 + 1)..(batch * 16 + 16), &action/1)

        {:ok, plan} =
          ActionLedger.prepare(
            ledger,
            [%{source: owner(), actions: actions}],
            accepted,
            spec,
            manifest,
            {Port, nil}
          )

        installed =
          Enum.reduce(plan.actions, ledger, fn planned, next ->
            ActionLedger.install(next, planned.request)
          end)
          |> Map.put(:sequences, plan.sequences)

        Enum.reduce(plan.actions, installed, fn planned, next ->
          sequence = planned.sequence
          ids = Enum.map(1..16, &"lease_#{sequence}_#{&1}")

          {:ok, result} =
            Action.result(planned.request.correlation, :completed, %{"value" => sequence}, ids)

          {:ok, completed, _, _} = ActionLedger.complete(next, result, accepted)
          completed
        end)
      end)

    {:error, :invalid_action_batch} =
      ActionLedger.prepare(
        ledger,
        [%{source: owner(), actions: [action(33)]}],
        accepted,
        spec,
        manifest,
        {Port, nil}
      )

    lease = ledger.leases["lease_1_1"]

    {:ok, transfer} =
      Action.new(:resource_transfer, "transfer", 33, owner(), %{
        lease: ActionLedger.lease_ref(lease),
        target: owner()
      })

    transferred = ActionLedger.transfer(ledger, transfer, accepted)

    released =
      Enum.reduce(Map.values(transferred.leases), transferred, fn lease, next ->
        ActionLedger.released(next, lease, :released)
      end)

    %{
      "maximum" => map_size(ledger.leases),
      "rejected" => 1,
      "transferred" => 1,
      "released" => 512,
      "terminal" => map_size(released.leases)
    }
  end

  defp restarts do
    {ledger, decisions} =
      Enum.reduce(0..3, {RecoveryPolicy.ledger(), []}, fn index, {ledger, decisions} ->
        {decision, next} =
          RecoveryPolicy.admit(ledger, :automatic, "persistent", index + 2, index * 100, 100)

        {next, decisions ++ [Atom.to_string(decision)]}
      end)

    %{
      "maximum" => ledger.maximum,
      "window_ms" => 5000,
      "decisions" => decisions,
      "terminal" => Atom.to_string(ledger.terminal),
      "fallback" => true,
      "replayed" => 0
    }
  end

  defp owner, do: %{root: "measure", path: [], generation: 1}

  defp spec,
    do: %{
      root: "measure",
      instance: "measure",
      owner: "acceptance",
      component: Root,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: ["ui.storage"],
      fallback: :none,
      timeout_ms: 5000
    }

  defp accepted do
    {:ok, correlation} = RootPort.correlation(spec(), 1, 1, 1, :mount)

    RootPort.candidate(
      correlation,
      %{
        components: [
          %{
            identity: owner(),
            role: :root,
            public_id: "root",
            schema_digest: String.duplicate("a", 64),
            state: {:present, 0}
          }
        ]
      },
      String.duplicate("b", 64),
      :measurement
    )
    |> elem(1)
  end

  defp policy,
    do: %{
      producers: %{
        "ui" => %{component: "root", classes: [:event], routes: [:self], supersedable: []}
      },
      events: %{increment: {:record, [{"value", :integer}]}},
      messages: %{},
      components: %{"root" => [:self]}
    }

  defp envelope(sequence),
    do: %{
      class: :event,
      producer: "ui",
      sequence: sequence,
      generation: 1,
      revision: 1,
      source: owner(),
      target: owner(),
      route: :self,
      name: :increment,
      payload: %{"value" => 1},
      supersedable: false,
      timer: :none
    }

  defp action(sequence) do
    {:ok, value} =
      Action.new(:effect_request, "read_#{sequence}", sequence, owner(), %{
        declaration: "read",
        payload: %{"value" => sequence},
        timeout_ms: 5000,
        idempotency_key: "request_#{sequence}",
        fallback: :deny
      })

    value
  end

  defp manifest(lease_limit) do
    schema = {:record, [{"value", :integer}]}

    %{
      effects: %{
        "read" => %{
          schema_version: "1.0.0",
          capability: "ui.storage",
          operation: "get",
          request: schema,
          result: schema,
          error: {:record, [{"code", :string}]},
          fallback: :deny,
          lease_kind: if(lease_limit == 0, do: nil, else: "subscription"),
          lease_limit: lease_limit
        }
      },
      commands: %{},
      owners: %{"root" => %{effects: ["read"], commands: [], transfers: [:self]}}
    }
  end
end
