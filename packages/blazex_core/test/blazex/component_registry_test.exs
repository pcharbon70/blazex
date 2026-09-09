defmodule BlazeX.ComponentRegistryTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{ComponentRegistry, Contract, Input, Schema}

  defmodule Pure do
    use BlazeX.Component,
      role: :pure,
      schema: [props: [{"label", [type: :string, required: true]}], slots: []]

    def render(_), do: {:output, {:semantic, 1, %{kind: :text, content: "pure"}}}
  end

  defmodule Stateful do
    use BlazeX.Component,
      role: :stateful,
      context: ["locale"],
      capabilities: ["ui.storage"],
      schema: [props: [], slots: []]

    def init(_), do: {:state, 0}
    def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  def entry(id \\ "pure", module \\ Pure) do
    m = module.__blazex_component__()

    %{
      id: id,
      module: module,
      role: m.role,
      contract_version: Contract.version(),
      schema_version: Schema.version(),
      runtimes: [:erts],
      capabilities: m.declarations.capabilities,
      contexts: m.declarations.context,
      actions: [],
      package: "example",
      visibility: :public,
      feature_bundle: nil
    }
  end

  def environment,
    do: %{
      root: "r",
      generation: 1,
      runtime: :erts,
      capabilities: ["ui.storage"],
      contexts: ["locale"],
      actions: []
    }

  def request,
    do: %{
      id: "pure",
      role: :pure,
      schema_version: Schema.version(),
      generation: 1,
      props: %{"label" => "text"},
      slots: %{}
    }

  def boundary, do: %{kind: :host, root: "r", owner: "r"}

  test "deterministic layer composition exports module-free metadata and validates invocations" do
    {:ok, a} =
      ComponentRegistry.new([[entry()], [entry("stateful", Stateful)], []], environment())

    {:ok, b} =
      ComponentRegistry.new([[entry("stateful", Stateful)], [], [entry()]], environment())

    assert ComponentRegistry.metadata(a) == ComponentRegistry.metadata(b)
    assert Input.portable?(ComponentRegistry.metadata(a))
    assert Enum.all?(ComponentRegistry.metadata(a).entries, &(not Map.has_key?(&1, :module)))

    assert {:ok, _, %{props: %{"label" => "text"}}} =
             ComponentRegistry.lookup(a, request(), ["pure"], boundary())

    assert {:error, _} =
             ComponentRegistry.lookup(a, %{request() | props: %{}}, ["pure"], boundary())
  end

  test "duplicate incompatible unavailable missing and undeclared entries reject at composition" do
    assert {:error, _} = ComponentRegistry.new([[entry()], [entry()]], environment())

    for changes <- [
          %{module: DoesNotExist},
          %{role: :root},
          %{schema_version: "unknown"},
          %{contract_version: "unknown"},
          %{runtimes: [:browser]},
          %{capabilities: ["undeclared"]},
          %{contexts: ["undeclared"]},
          %{actions: ["undeclared"]},
          %{visibility: :secret}
        ] do
      assert {:error, _} = ComponentRegistry.new([[Map.merge(entry(), changes)]], environment())
    end

    assert {:error, _} =
             ComponentRegistry.new([[entry("stateful", Stateful)]], %{
               environment()
               | capabilities: []
             })

    assert {:error, _} =
             ComponentRegistry.new([Enum.map(1..129, &entry("id_#{&1}"))], environment())
  end

  test "forged IDs generations roles modules and caller authority never dispatch" do
    {:ok, registry} = ComponentRegistry.new([[entry()]], environment())

    for changes <- [
          %{id: "Elixir.System"},
          %{generation: 2},
          %{role: :stateful},
          %{schema_version: "unknown"},
          %{module: "System"},
          %{props: %{"label" => self()}},
          %{props: %{"authorization" => true}}
        ] do
      assert {:error, :unavailable_component} =
               ComponentRegistry.lookup(
                 registry,
                 Map.merge(request(), changes),
                 ["pure"],
                 boundary()
               )
    end

    assert {:error, _} = ComponentRegistry.lookup(registry, request(), [], boundary())

    assert {:error, _} =
             ComponentRegistry.lookup(registry, request(), ["pure"], %{boundary() | root: "other"})

    {:ok, private} = ComponentRegistry.new([[%{entry() | visibility: :private}]], environment())
    assert {:error, _} = ComponentRegistry.lookup(private, request(), ["pure"], boundary())
  end
end
