Code.require_file("scoped_evaluator_test.exs", __DIR__)

defmodule BlazeX.RegistryEvaluatorTest do
  use ExUnit.Case, async: true

  alias BlazeX.Component.{
    ComponentRegistry,
    Contract,
    LocalView,
    Schema,
    ScheduledView,
    ScopedView
  }

  alias BlazeX.UITree.ScopedEvaluator
  alias BlazeX.ScopedEvaluatorTest, as: F

  defmodule Other do
    use BlazeX.Component, role: :stateful, context: ["locale"], schema: [props: [], slots: []]
    def init(_), do: {:state, "other"}

    def render(%{state: {:present, value}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: value}}}

    def dispose(_), do: :ok
  end

  def entry(id, module),
    do: %{
      id: id,
      module: module,
      role: :stateful,
      contract_version: Contract.version(),
      schema_version: Schema.version(),
      runtimes: [:erts],
      capabilities: [],
      contexts: ["locale"],
      actions: [],
      package: "fixtures",
      visibility: :public,
      feature_bundle: nil
    }

  def config(fallback \\ nil) do
    {:ok, registry} =
      ComponentRegistry.new(
        [[entry("child", F.Child), entry("other", Other)]],
        %{
          root: "scoped",
          generation: 1,
          runtime: :erts,
          capabilities: [],
          contexts: ["locale"],
          actions: []
        }
      )

    config = F.config()

    config =
      put_in(config, [:scope, :manifest, :owners, "other"], %{provide: [], consume: ["locale"]})

    %{
      config
      | scope:
          Map.merge(config.scope, %{
            registry: registry,
            calls: %{
              "child" => %{
                initial: "child",
                allowed: ["child", "other"],
                role: :stateful,
                schema_version: Schema.version(),
                fallback: fallback
              }
            }
          })
    }
  end

  test "registered stateful selection retains same-ID state and replaces identity on ID change" do
    supervisor = start_supervised!(LocalView.Supervisor)

    ports = %{
      evaluator: {ScopedEvaluator, config()},
      renderer: {F.Port, self()},
      host: {F.Port, self()}
    }

    {:ok, handle} = ScheduledView.start(supervisor, F.spec(), ports, F.policy())
    assert_receive {:submission, mount, before}
    F.commit(supervisor, handle, mount)
    {:ok, _} = ScopedView.select(supervisor, handle, 1, 1, 1, %{"child" => "child"})
    assert_receive {:submission, same, candidate}
    assert List.last(candidate.state.components).state == List.last(before.state.components).state
    F.commit(supervisor, handle, same)
    {:ok, _} = ScopedView.select(supervisor, handle, 1, 2, 1, %{"child" => "other"})
    assert_receive {:submission, replacement, candidate}
    assert List.last(candidate.state.components).public_id == "other"
    assert List.last(candidate.state.components).state == {:present, "other"}

    assert List.last(candidate.state.components).identity !=
             List.last(before.state.components).identity

    assert Enum.all?(
             candidate.token.scope.context.bindings,
             &(&1.consumer != List.last(before.state.components).identity)
           )

    F.commit(supervisor, handle, replacement)
    assert {:error, _} = ScopedView.select(supervisor, handle, 1, 3, 2, %{"child" => "child"})
    refute_receive {:submission, _, _}, 20
  end

  test "unknown IDs use only a caller-declared registered fallback" do
    supervisor = start_supervised!(LocalView.Supervisor)

    ports = %{
      evaluator: {ScopedEvaluator, config("other")},
      renderer: {F.Port, self()},
      host: {F.Port, self()}
    }

    {:ok, handle} = ScheduledView.start(supervisor, F.spec(), ports, F.policy())
    assert_receive {:submission, mount, _}
    F.commit(supervisor, handle, mount)
    {:ok, _} = ScopedView.select(supervisor, handle, 1, 1, 1, %{"child" => "forged-module"})
    assert_receive {:submission, fallback, candidate}
    assert [%{status: :fallback, selected: "other"}] = candidate.token.scope.registry_outcomes
    F.commit(supervisor, handle, fallback)

    assert {:error, _} =
             ScopedView.select(supervisor, handle, 1, 2, 1, %{"unknown-site" => "child"})
  end
end
