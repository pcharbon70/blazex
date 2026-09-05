defmodule BlazeX.EffectsBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.Effects.{Capability, Effect, Error, Negotiation, Resource, Result, Tracker}

  test "the boundary depends inward only on core" do
    assert Code.ensure_loaded?(BlazeX.Core)
    assert Code.ensure_loaded?(BlazeX.Effects)
  end

  test "capabilities expose the exact proof vocabulary and operations" do
    assert Capability.names() == [:time, :"ui.clipboard", :"ui.files.choose", :"ui.storage"]

    assert Capability.operations() == %{
             :time => [:schedule],
             :"ui.clipboard" => [:read, :write],
             :"ui.files.choose" => [:choose],
             :"ui.storage" => [:get, :put, :delete]
           }

    assert {:ok, required} = Capability.new(:time, :required, :fail)
    assert Capability.valid?(required)
    assert {:error, :invalid_fallback} = Capability.new(:time, :required, :omit)
    assert {:error, :invalid_fallback} = Capability.new(:time, :optional, :fail)
    assert {:error, :unknown_capability} = Capability.new(:network, :required, :fail)
  end

  test "negotiation is deny by default and records explicit fallback outcomes" do
    assert {:ok, time} = Capability.new(:time, :required, :fail)
    assert {:ok, clipboard} = Capability.new(:"ui.clipboard", :required, :component)
    assert {:ok, files} = Capability.new(:"ui.files.choose", :optional, :omit)

    assert {:ok, negotiation} = Negotiation.negotiate([time, clipboard, files], [:time])
    assert negotiation.granted == [:time]
    assert negotiation.fallbacks == [:"ui.clipboard"]
    assert negotiation.omitted == [:"ui.files.choose"]

    assert {:error, %Error{code: :required_capability_missing, detail: :time}} =
             Negotiation.negotiate([time], [])

    assert {:error, %Error{code: :duplicate_requirement}} =
             Negotiation.negotiate([time, time], [:time])

    assert {:error, %Error{code: :duplicate_grant}} =
             Negotiation.negotiate([], [:time, :time])

    assert {:error, %Error{code: :unknown_grant}} = Negotiation.negotiate([], [:network])
    assert {:error, %Error{code: :invalid_requirement}} = Negotiation.negotiate([time | :bad], [])
  end

  test "effects and results accept only portable provider-neutral data" do
    owner = identity!(:component)

    assert {:ok, effect} =
             Effect.new("clipboard-read", owner, :"ui.clipboard", :read, %{},
               timeout_ms: 1_000,
               fallback: :component
             )

    assert Effect.valid?(effect)
    assert {:error, :invalid_operation} = Effect.new("bad-op", owner, :time, :read)

    assert {:error, :invalid_payload} =
             Effect.new("bad-payload", owner, :time, :schedule, %{pid: self()})

    assert {:error, :invalid_timeout} =
             Effect.new("bad-timeout", owner, :time, :schedule, %{}, timeout_ms: 0)

    assert {:ok, result} = Result.new(effect.id, owner, :ok, %{text: "copied"})
    assert result.status == :ok
    assert Result.statuses() == [:ok, :denied, :cancelled, :timeout, :unsupported, :failed]
    assert {:error, :unexpected_result_value} = Result.new(effect.id, owner, :denied, %{})
  end

  test "the tracker denies absent authority and never reuses an effect id" do
    owner = identity!(:component)
    effect = effect!("denied", owner, :time, :schedule)
    assert {:ok, tracker} = Tracker.new()

    assert {:ok, denied_tracker, %Result{status: :denied, value: nil}} =
             Tracker.submit(tracker, effect)

    assert denied_tracker.pending == %{}
    assert {:error, %Error{code: :duplicate_effect_id}} = Tracker.submit(denied_tracker, effect)
  end

  test "pending effects have one deterministic terminal outcome" do
    owner = identity!(:component)
    assert {:ok, tracker} = Tracker.new([:time])

    Enum.each(
      [
        {"complete", :complete, :ok},
        {"cancel", :cancel, :cancelled},
        {"timeout", :timeout, :timeout},
        {"fail", :fail, :failed}
      ],
      fn {id, action, status} ->
        effect = effect!(id, owner, :time, :schedule)
        assert {:ok, pending, :pending} = Tracker.submit(tracker, effect)

        completed =
          case action do
            :complete -> Tracker.complete(pending, id, %{tick: 1})
            terminal -> apply(Tracker, terminal, [pending, id])
          end

        assert {:ok, terminal_tracker, %Result{status: ^status}} = completed
        assert terminal_tracker.pending == %{}
        assert {:error, %Error{code: :effect_not_pending}} = Tracker.cancel(terminal_tracker, id)
      end
    )
  end

  test "opaque resources transfer explicitly and disposal is idempotent" do
    owner = identity!(:component)
    new_owner = identity!(:receiver)
    effect = effect!("file-choice", owner, :"ui.files.choose", :choose)
    assert {:ok, tracker} = Tracker.new([:"ui.files.choose"])
    assert {:ok, pending, :pending} = Tracker.submit(tracker, effect)

    assert {:ok, active, %Result{status: :ok, value: resource}, resource} =
             Tracker.complete_resource(pending, effect.id, "selection-1")

    assert %Resource{owner: ^owner, generation: 1} = resource
    assert {:ok, :active} = Tracker.resource_state(active, resource)
    assert {:ok, transferred, new_resource} = Tracker.transfer(active, resource, new_owner)
    assert new_resource.owner == new_owner
    assert {:error, %Error{code: :resource_not_found}} = Tracker.dispose(transferred, resource)
    assert {:ok, disposed} = Tracker.dispose(transferred, new_resource)
    assert {:ok, same} = Tracker.dispose(disposed, new_resource)
    assert same == disposed
    assert {:ok, :disposed} = Tracker.resource_state(same, new_resource)
  end

  test "resource transfer rejects a different owner generation" do
    owner = identity!(:component)
    assert {:ok, stale_owner} = Identity.replace(identity!(:receiver))
    effect = effect!("storage", owner, :"ui.storage", :get)
    assert {:ok, tracker} = Tracker.new([:"ui.storage"])
    assert {:ok, pending, :pending} = Tracker.submit(tracker, effect)
    assert {:ok, active, _result, resource} = Tracker.complete_resource(pending, effect.id, "db")

    assert {:error, %Error{code: :generation_mismatch}} =
             Tracker.transfer(active, resource, stale_owner)
  end

  test "owner cleanup cancels pending work and disposes only its generation" do
    owner = identity!(:component)
    assert {:ok, next_generation} = Identity.replace(owner)
    assert {:ok, tracker} = Tracker.new([:time, :"ui.storage"])

    own_pending = effect!("own-pending", owner, :time, :schedule)
    next_pending = effect!("next-pending", next_generation, :time, :schedule)
    own_resource_effect = effect!("own-resource", owner, :"ui.storage", :get)

    assert {:ok, tracker, :pending} = Tracker.submit(tracker, own_pending)
    assert {:ok, tracker, :pending} = Tracker.submit(tracker, next_pending)
    assert {:ok, tracker, :pending} = Tracker.submit(tracker, own_resource_effect)

    assert {:ok, tracker, _result, resource} =
             Tracker.complete_resource(tracker, own_resource_effect.id, "owned-db")

    assert {:ok, cleaned, [%Result{effect_id: "own-pending", status: :cancelled}]} =
             Tracker.dispose_owner(tracker, owner)

    assert Map.has_key?(cleaned.pending, "next-pending")
    refute Map.has_key?(cleaned.pending, "own-pending")
    assert {:ok, :disposed} = Tracker.resource_state(cleaned, resource)
  end

  defp identity!(root) do
    {:ok, identity} = Identity.new(root)
    identity
  end

  defp effect!(id, owner, capability, operation) do
    {:ok, effect} = Effect.new(id, owner, capability, operation)
    effect
  end
end
