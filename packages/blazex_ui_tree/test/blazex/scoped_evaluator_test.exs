defmodule BlazeX.ScopedEvaluatorTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{LocalView, ScheduledView, ScopedView}
  alias BlazeX.UITree.ScopedEvaluator

  defmodule Root do
    use BlazeX.Component, role: :root, context: ["locale"], schema: [props: [], slots: []]
    def mount(_), do: {:state, 0}
    def update(%{state: {:present, n}}), do: {:state, n + 1}

    def render(%{contexts: %{"locale" => value}}),
      do: {:output, {:semantic, 1, %{kind: :group, accessibility: %{role: :group, name: value}}}}

    def terminate(_), do: :ok
  end

  defmodule Child do
    use BlazeX.Component, role: :stateful, context: ["locale"], schema: [props: [], slots: []]
    def init(%{contexts: %{"locale" => value}}), do: {:state, value}
    def update(%{contexts: %{"locale" => value}}), do: {:state, value}

    def render(%{state: {:present, value}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: value}}}

    def dispose(_), do: :ok
  end

  defmodule Port do
    def submit(pid, correlation, candidate) do
      send(pid, {:submission, correlation, candidate})
      :ok
    end

    def cancel(_, _), do: :ok
    def notify(_, _), do: :ok
  end

  def owner, do: %{root: "scoped", path: [], generation: 1}
  def providers(value), do: [%{owner: owner(), name: "locale", value: value}]

  def config(mode \\ :tracked) do
    root = %{
      module: Root,
      public_id: "root",
      site: "site",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child"]
    }

    %{
      reference: "root",
      graph: %{
        "root" => root,
        "child" => %{root | module: Child, public_id: "child", key: "child", children: []}
      },
      scope: %{
        boundary: :host,
        providers: providers("old"),
        manifest: %{
          definitions: %{
            "locale" => %{
              version: 1,
              schema: :string,
              boundary: :host,
              mode: mode,
              default: {:present, "default"},
              doc: "Public",
              visibility: :public,
              advisory: false
            }
          },
          owners: %{
            "root" => %{provide: ["locale"], consume: ["locale"]},
            "child" => %{provide: [], consume: ["locale"]}
          }
        }
      }
    }
  end

  def spec,
    do: %{
      root: "scoped",
      instance: "instance",
      owner: "runtime",
      public_id: "root",
      component: Root,
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 5000
    }

  def policy,
    do: %{
      producers: %{
        "ui" => %{component: "root", classes: [:event], routes: [:self], supersedable: []}
      },
      events: %{increment: :integer},
      messages: %{},
      components: %{"root" => [:self]}
    }

  def start(mode \\ :tracked) do
    supervisor = start_supervised!(LocalView.Supervisor)

    ports = %{
      evaluator: {ScopedEvaluator, config(mode)},
      renderer: {Port, self()},
      host: {Port, self()}
    }

    {:ok, handle} = ScheduledView.start(supervisor, spec(), ports, policy())
    assert_receive {:submission, mount, _}
    commit(supervisor, handle, mount)
    {supervisor, handle}
  end

  def commit(supervisor, handle, correlation),
    do:
      assert(
        :ok ==
          LocalView.acknowledge(supervisor, handle, %{
            correlation: correlation,
            result: :committed
          })
      )

  test "provider commit precedes canonical consumer updates and stale notices never reach callbacks" do
    {supervisor, handle} = start()
    {:ok, _} = ScopedView.change(supervisor, handle, 1, 1, providers("new"))
    assert_receive {:submission, provider_commit, candidate}
    assert Enum.map(candidate.token.scope.context.bindings, & &1.value) == ["old", "old"]

    assert candidate.token.scope.context.pending ==
             Enum.map(candidate.state.components, & &1.identity)

    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.scheduling.reserved == 2
    refute_receive {:submission, _, _}, 20
    commit(supervisor, handle, provider_commit)
    assert_receive {:submission, first, candidate}
    assert Enum.map(candidate.token.scope.context.bindings, & &1.value) == ["new", "old"]
    commit(supervisor, handle, first)
    assert_receive {:submission, second, candidate}
    assert Enum.map(candidate.token.scope.context.bindings, & &1.value) == ["new", "new"]
    assert candidate.token.scope.context.pending == []
    commit(supervisor, handle, second)
    assert {:error, _} = ScopedView.change(supervisor, handle, 1, 1, providers("stale"))
    assert {:error, _} = ScopedView.change(supervisor, handle, 2, 2, providers("foreign"))
    refute_receive {:submission, _, _}, 20
  end

  test "renderer rejection does not publish provider values or schedule subscriptions" do
    {supervisor, handle} = start()
    {:ok, _} = ScopedView.change(supervisor, handle, 1, 1, providers("new"))
    assert_receive {:submission, pending, _}

    assert {:error, :renderer_rejected} =
             LocalView.acknowledge(supervisor, handle, %{correlation: pending, result: :rejected})

    refute_receive {:submission, _, _}, 20
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.scheduling.depth == 0
    assert {:ok, _} = ScopedView.change(supervisor, handle, 1, 1, providers("retry"))
    assert_receive {:submission, _, candidate}
    assert hd(candidate.token.scope.context.bindings).value == "old"
  end

  test "fixed context and malformed duplicate provider changes reject before rendering" do
    {supervisor, handle} = start(:fixed)
    {:ok, _} = ScopedView.change(supervisor, handle, 1, 1, providers("changed"))
    refute_receive {:submission, _, _}, 20
    {:ok, _} = ScopedView.change(supervisor, handle, 1, 1, providers("old") ++ providers("old"))
    refute_receive {:submission, _, _}, 20
    {:ok, snapshot} = LocalView.inspect_root(supervisor, handle)
    assert snapshot.accepted.correlation.revision == 1 and snapshot.scheduling.depth == 0
  end
end
