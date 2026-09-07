defmodule BlazeX.Renderer.DOM.ReconciledSessionTest do
  use ExUnit.Case, async: true
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.Node
  alias BlazeX.Renderer.DOM.{Incremental, ReconciledSession}

  defp tree(text \\ "hello", generation \\ 1) do
    {:ok, id} = Identity.new(:session, generation)
    {:ok, node} = Node.text(id, text)
    node
  end

  defp ack(facade, state \\ "committed") do
    facade
    |> ReconciledSession.transaction()
    |> Map.take(
      ~w(protocol schema owner generation root base_revision target_revision transaction_id digest)
    )
    |> Map.merge(%{
      "record" => "ack",
      "state" => state,
      "diagnostic" => if(state in ~w(rejected rolled-back fallback), do: "apply", else: nil)
    })
  end

  defp mount do
    {:ok, pending} = ReconciledSession.mount(tree())
    {:ok, accepted} = ReconciledSession.acknowledge(pending, ack(pending))
    accepted
  end

  test "mount and progress leave accepted state empty until committed" do
    {:ok, pending} = ReconciledSession.mount(tree())
    assert pending.accepted == nil and pending.state.accepted == nil
    assert pending.pending.revision == 0 and pending.state.revision == 0
    assert pending.pending.backend == Incremental
    assert {:ok, preflight} = ReconciledSession.acknowledge(pending, ack(pending, "preflight"))
    assert {:ok, accepted} = ReconciledSession.acknowledge(preflight, ack(pending, "accepted"))
    assert accepted.accepted == nil and accepted.state.accepted == nil

    assert {:error, "acknowledgement-mismatch"} =
             ReconciledSession.acknowledge(accepted, ack(pending, "preflight"))

    assert {:error, "acknowledgement-mismatch"} =
             ReconciledSession.acknowledge(accepted, ack(pending, "accepted"))

    {:ok, committed} = ReconciledSession.acknowledge(accepted, ack(pending))
    assert committed.accepted.revision == 0 and committed.state.revision == 1
    assert committed.pending == nil and committed.state.pending == nil
  end

  test "update advances both accepted projections and neutral metadata only on ack" do
    old = mount()
    {:ok, pending} = ReconciledSession.update(old, tree("next"))
    assert pending.accepted == old.accepted
    assert pending.state.accepted == old.state.accepted
    assert pending.pending.revision == 1 and pending.state.revision == 1
    {:ok, next} = ReconciledSession.acknowledge(pending, ack(pending))
    assert next.accepted.revision == 1 and next.state.revision == 2
    refute next.state.accepted == old.state.accepted
  end

  test "rejection and rollback release pending data and make retry identity fresh" do
    for outcome <- ~w(rejected rolled-back) do
      old = mount()
      {:ok, pending} = ReconciledSession.update(old, tree("next"))
      delayed = ack(pending)
      {:ok, rejected} = ReconciledSession.acknowledge(pending, ack(pending, outcome))
      assert rejected.state.accepted == old.state.accepted and rejected.pending == nil
      {:ok, retry} = ReconciledSession.update(rejected, tree("next"))
      refute ReconciledSession.transaction(retry)["transaction_id"] == delayed["transaction_id"]
      assert {:error, "acknowledgement-mismatch"} = ReconciledSession.acknowledge(retry, delayed)
      assert {:ok, _} = ReconciledSession.acknowledge(retry, ack(retry))
    end
  end

  test "failed initial mount retries without reusing an attempt identity" do
    {:ok, pending} = ReconciledSession.mount(tree())
    old_ack = ack(pending)
    {:ok, rejected} = ReconciledSession.acknowledge(pending, ack(pending, "rejected"))
    assert rejected.accepted == nil
    {:ok, retry} = ReconciledSession.mount(rejected, tree())
    assert {:error, "acknowledgement-mismatch"} = ReconciledSession.acknowledge(retry, old_ack)
    assert {:ok, _} = ReconciledSession.acknowledge(retry, ack(retry))
  end

  test "wrong generation revision digest owner root and out-of-order ack reject" do
    old = mount()
    {:ok, pending} = ReconciledSession.update(old, tree("next"))

    for {field, value} <- [
          {"generation", 2},
          {"base_revision", 0},
          {"target_revision", 10},
          {"digest", String.duplicate("0", 64)},
          {"owner", "root-wrong"},
          {"root", "bx-" <> String.duplicate("0", 24)}
        ] do
      assert {:error, "acknowledgement-mismatch"} =
               ReconciledSession.acknowledge(pending, Map.put(ack(pending), field, value))
    end

    assert pending.accepted == old.accepted
    {:ok, next} = ReconciledSession.acknowledge(pending, ack(pending))
    assert {:error, "duplicate"} = ReconciledSession.acknowledge(next, ack(pending))
  end

  test "pending supersession and fallback are explicitly denied" do
    {:ok, pending} = ReconciledSession.update(mount(), tree("next"))
    assert {:error, "pending-transaction"} = ReconciledSession.update(pending, tree("later"))
    assert {:error, "pending-transaction"} = ReconciledSession.dispose(pending)

    assert {:error, "replacement-not-authorized"} =
             ReconciledSession.acknowledge(pending, ack(pending, "fallback"))
  end

  test "generation replacement preserves old generation until commit" do
    old = mount()
    {:ok, pending} = ReconciledSession.replace(old, tree("next", 2))
    assert pending.accepted.generation == 1 and pending.state.accepted.generation == 1
    assert ReconciledSession.transaction(pending)["kind"] == "replace"
    {:ok, next} = ReconciledSession.acknowledge(pending, ack(pending))

    assert next.accepted.generation == 2 and next.accepted.revision == 0 and
             next.state.revision == 2
  end

  test "disposal is committed only by disposed ack and is terminal/idempotent" do
    old = mount()
    {:ok, pending} = ReconciledSession.dispose(old)
    assert pending.accepted.status == :mounted and pending.state.accepted != nil

    assert {:error, "acknowledgement-mismatch"} =
             ReconciledSession.acknowledge(pending, ack(pending))

    {:ok, disposed} = ReconciledSession.acknowledge(pending, ack(pending, "disposed"))
    assert disposed.accepted.status == :disposed and disposed.state.accepted == nil
    assert {:ok, ^disposed} = ReconciledSession.dispose(disposed)
    assert {:error, "disposed-root"} = ReconciledSession.update(disposed, tree())

    assert {:error, "disposed-root"} =
             ReconciledSession.acknowledge(disposed, ack(pending, "disposed"))
  end

  test "direct backend callbacks reject provisional and incompatible state" do
    old = mount()
    {:ok, context} = BlazeX.Renderer.Context.new(old.accepted.owner, 1, :update)
    {:ok, pending, artifact} = Incremental.update(old.state, tree("next"), context)
    assert artifact.format == :dom_transaction_v2
    assert {:error, "pending-transaction"} = Incremental.update(pending, tree(), context)

    assert {:error, "incompatible-state"} =
             Incremental.update(%{old.state | version: 2}, tree(), context)

    assert {:error, "incompatible-state"} =
             Incremental.update(old.state, tree(), %{context | revision: 9})
  end

  test "an unsupported empty state version is not silently remounted" do
    facade = %ReconciledSession{state: %Incremental{version: 2}}
    assert {:error, "incompatible-state"} = ReconciledSession.mount(facade, tree())
  end

  test "corrupt pending data cannot be promoted by a correctly shaped acknowledgement" do
    {:ok, pending} = ReconciledSession.mount(tree())
    bad = put_in(pending.state.pending.projection.fingerprint, "corrupt")
    assert {:error, "acknowledgement-mismatch"} = ReconciledSession.acknowledge(bad, ack(pending))
    assert pending.state.accepted == nil
  end
end
