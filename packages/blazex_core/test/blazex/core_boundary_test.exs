defmodule BlazeX.CoreBoundaryTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Evaluator

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

  defp valid_root do
    {:ok, identity} = BlazeX.Core.Identity.new(:test)
    identity
  end
end
