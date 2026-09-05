defmodule BlazeX.CoreBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.{Evaluator, Event}

  defmodule PureComponent do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure

    @impl true
    def render(props, context), do: {:ok, {:pure, props, context.identity, context.revision}}
  end

  defmodule StatefulComponent do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(props, _context), do: {:ok, %{count: props.initial}}

    @impl true
    def update(props, state, _context), do: {:ok, %{state | count: state.count + props.increment}}

    @impl true
    def render(_props, state, context),
      do: {:ok, {:stateful, state.count, context.identity, context.transition}}
  end

  defmodule RejectingComponent do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure

    @impl true
    def render(_props, _context), do: {:error, %{opaque: self()}}
  end

  defmodule RaisingComponent do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure

    @impl true
    def render(_props, _context), do: raise("private failure")
  end

  defmodule MissingRender do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :pure
  end

  defmodule InvalidMode do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :renderer_owned
  end

  defmodule InvalidState do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(_props, _context), do: {:ok, self()}

    @impl true
    def update(_props, state, _context), do: {:ok, state}

    @impl true
    def render(_props, state, _context), do: {:ok, state}
  end

  defmodule EventCounter do
    @behaviour BlazeX.Core.Component

    @impl true
    def mode, do: :stateful

    @impl true
    def init(props, _context), do: {:ok, %{count: props.initial}}

    @impl true
    def update(_props, state, _context), do: {:ok, state}

    @impl true
    def handle_event(%Event{name: :increment, payload: payload}, _props, state, _context) do
      {:ok, %{state | count: state.count + payload.amount}, [{:effect, :time, :schedule}]}
    end

    @impl true
    def render(_props, state, context),
      do: {:ok, {:event_counter, state.count, context.identity, context.transition}}
  end

  test "the experimental module root compiles without dependencies" do
    assert Code.ensure_loaded?(BlazeX.Core)
  end

  test "identity is structural and replacement advances only its generation" do
    assert {:ok, root} = BlazeX.Core.Identity.new({:component, "cart"})
    assert {:ok, child} = BlazeX.Core.Identity.child(root, {:item, 7})
    assert child.path == [{:item, 7}]
    assert child.generation == 1

    assert {:ok, replacement} = BlazeX.Core.Identity.replace(child)
    assert replacement.root == child.root
    assert replacement.path == child.path
    assert replacement.generation == 2
  end

  test "identity accepts only bounded portable keys" do
    assert BlazeX.Core.Identity.portable_key?(:root)
    assert BlazeX.Core.Identity.portable_key?({:item, [1, "two"]})

    refute BlazeX.Core.Identity.portable_key?(nil)
    refute BlazeX.Core.Identity.portable_key?(self())
    refute BlazeX.Core.Identity.portable_key?(make_ref())
    refute BlazeX.Core.Identity.portable_key?(fn -> :opaque end)
    refute BlazeX.Core.Identity.portable_key?(%{opaque: true})
    refute BlazeX.Core.Identity.portable_key?(1.5)
    refute BlazeX.Core.Identity.portable_key?([:valid | :improper])
  end

  test "identity rejects malformed roots and generations" do
    assert {:error, :invalid_root} = BlazeX.Core.Identity.new(%{})
    assert {:error, :invalid_generation} = BlazeX.Core.Identity.new(:root, 0)
    assert {:error, :invalid_key} = BlazeX.Core.Identity.child(valid_root(), self())
  end

  test "pure evaluation preserves identity and advances revision on update" do
    identity = valid_root()
    assert {:ok, mounted} = Evaluator.mount(PureComponent, identity, %{label: "one"})
    assert mounted.mode == :pure
    assert mounted.revision == 0
    assert mounted.output == {:pure, %{label: "one"}, identity, 0}

    assert {:ok, updated} = Evaluator.update(mounted, %{label: "two"})
    assert updated.identity == identity
    assert updated.revision == 1
    assert updated.output == {:pure, %{label: "two"}, identity, 1}
  end

  test "stateful evaluation initializes and updates portable state" do
    identity = valid_root()
    assert {:ok, mounted} = Evaluator.mount(StatefulComponent, identity, %{initial: 2})
    assert mounted.state == %{count: 2}

    assert {:ok, updated} = Evaluator.update(mounted, %{increment: 3})
    assert updated.state == %{count: 5}
    assert updated.output == {:stateful, 5, identity, :update}
  end

  test "replacement increments generation and restarts evaluation" do
    identity = valid_root()
    assert {:ok, mounted} = Evaluator.mount(StatefulComponent, identity, %{initial: 2})
    assert {:ok, replaced} = Evaluator.replace(mounted, %{initial: 9})
    assert replaced.identity.generation == identity.generation + 1
    assert replaced.identity.root == identity.root
    assert replaced.identity.path == identity.path
    assert replaced.revision == 0
    assert replaced.state == %{count: 9}
    assert replaced.output == {:stateful, 9, replaced.identity, :replace}
  end

  test "evaluation rejects opaque props and strips callback reasons" do
    identity = valid_root()

    assert {:error, %{code: :invalid_props}} =
             Evaluator.mount(PureComponent, identity, %{process: self()})

    assert {:error, rejected} = Evaluator.mount(RejectingComponent, identity, %{})
    assert rejected.code == :callback_rejected
    assert rejected.stage == :render
    assert rejected.detail == :render
  end

  test "evaluation normalizes raised callbacks without exception text" do
    assert {:error, diagnostic} = Evaluator.mount(RaisingComponent, valid_root(), %{})
    assert diagnostic.code == :callback_failed
    assert diagnostic.stage == :render
    assert diagnostic.detail == :render
    refute Map.has_key?(Map.from_struct(diagnostic), :message)
  end

  test "evaluation rejects malformed contracts and opaque state" do
    identity = valid_root()

    assert {:error, %{code: :missing_callback, detail: :render}} =
             Evaluator.mount(MissingRender, identity, %{})

    assert {:error, %{code: :invalid_mode}} = Evaluator.mount(InvalidMode, identity, %{})

    assert {:error, %{code: :invalid_state, stage: :init}} =
             Evaluator.mount(InvalidState, identity, %{})
  end

  test "semantic events validate intent, lineage, payload, and sequence" do
    owner = valid_root()
    {:ok, source} = BlazeX.Core.Identity.child(owner, {:action, :increment})

    assert {:ok, event} = Event.new(:activate, owner, source, %{button: :primary}, 1)
    assert Event.valid?(event)
    assert event.version == 1
    assert {:ok, %Event{name: :change}} = Event.new(:change, owner, source, %{value: "new"}, 2)
    assert {:ok, %Event{name: :select}} = Event.new(:select, owner, source, %{key: 7}, 3)

    assert Event.names() == [
             :activate,
             :change,
             :submit,
             :select,
             :expand,
             :dismiss,
             :move,
             :reorder,
             :increment,
             :decrement,
             :request_open,
             :request_close,
             :request_page
           ]

    assert {:error, :unknown_event} = Event.new(:click, owner, source)
    assert {:error, :invalid_payload} = Event.new(:activate, owner, source, %{pid: self()})
    assert {:error, :invalid_sequence} = Event.new(:activate, owner, source, %{}, 0)

    {:ok, foreign} = BlazeX.Core.Identity.new(:foreign)
    assert {:error, :source_outside_owner} = Event.new(:activate, owner, foreign)
  end

  test "stateful dispatch advances revision and event sequence atomically" do
    owner = valid_root()
    {:ok, source} = BlazeX.Core.Identity.child(owner, {:action, :increment})
    {:ok, event} = Event.new(:increment, owner, source, %{amount: 3}, 1)
    assert {:ok, mounted} = Evaluator.mount(EventCounter, owner, %{initial: 2})

    assert {:ok, dispatched, emissions} = Evaluator.dispatch(mounted, event)
    assert dispatched.state == %{count: 5}
    assert dispatched.revision == 1
    assert dispatched.last_event_sequence == 1
    assert dispatched.output == {:event_counter, 5, owner, :event}
    assert emissions == [{:effect, :time, :schedule}]

    assert {:error, %{code: :stale_event_sequence}} = Evaluator.dispatch(dispatched, event)
  end

  test "dispatch rejects pure, wrong-owner, and stale-generation events" do
    owner = valid_root()
    {:ok, source} = BlazeX.Core.Identity.child(owner, :source)
    {:ok, event} = Event.new(:activate, owner, source)
    assert {:ok, pure} = Evaluator.mount(PureComponent, owner, %{})
    assert {:error, %{code: :event_requires_stateful}} = Evaluator.dispatch(pure, event)

    {:ok, other_owner} = BlazeX.Core.Identity.new(:other)
    {:ok, other_source} = BlazeX.Core.Identity.child(other_owner, :source)
    {:ok, wrong_event} = Event.new(:activate, other_owner, other_source)
    assert {:ok, stateful} = Evaluator.mount(EventCounter, owner, %{initial: 0})
    assert {:error, %{code: :event_owner_mismatch}} = Evaluator.dispatch(stateful, wrong_event)

    assert {:ok, replaced} = Evaluator.replace(stateful, %{initial: 0})
    assert {:error, %{code: :stale_event}} = Evaluator.dispatch(replaced, event)
  end

  defp valid_root do
    {:ok, identity} = BlazeX.Core.Identity.new(:test)
    identity
  end
end
