defmodule BlazeX.Component.ComponentRegistry do
  @moduledoc "Explicit already-loaded component registry; public exports contain no module targets."
  alias BlazeX.Component.{Action, Contract, Invocation, NestedTable, Schema}
  defstruct [:root, :generation, :runtime, :entries]

  @keys [
    :id,
    :module,
    :role,
    :contract_version,
    :schema_version,
    :runtimes,
    :capabilities,
    :contexts,
    :actions,
    :package,
    :visibility,
    :feature_bundle
  ]

  def new(layers, environment) do
    true =
      Action.keys?(environment, [:root, :generation, :runtime, :capabilities, :contexts, :actions])

    true = Schema.name?(environment.root) and Action.positive?(environment.generation)
    true = environment.runtime in [:erts, :atomvm]
    true = is_list(layers) and length(layers) in 1..3 and Enum.all?(layers, &is_list/1)
    entries = List.flatten(layers)
    true = length(entries) <= 128
    true = length(Enum.uniq_by(entries, & &1.id)) == length(entries)

    entries =
      Enum.map(entries, fn entry ->
        true = Action.keys?(entry, @keys)
        true = Schema.name?(entry.id) and Schema.name?(entry.package)
        true = entry.visibility in [:public, :private]
        true = entry.feature_bundle == nil or Schema.name?(entry.feature_bundle)

        true =
          entry.contract_version == Contract.version() and
            entry.schema_version == Schema.version()

        true =
          is_list(entry.runtimes) and entry.runtimes != [] and
            Enum.uniq(entry.runtimes) == entry.runtimes

        true =
          Enum.all?(entry.runtimes, &(&1 in [:erts, :atomvm])) and
            environment.runtime in entry.runtimes

        true =
          is_atom(entry.module) and function_exported?(entry.module, :__blazex_component__, 0)

        metadata = entry.module.__blazex_component__()
        true = metadata.version == Schema.version() and metadata.role == entry.role
        true = entry.role in [:pure, :stateful, :root]

        true =
          entry.capabilities == metadata.declarations.capabilities and
            entry.contexts == metadata.declarations.context

        for {required, available} <- [
              {entry.capabilities, environment.capabilities},
              {entry.contexts, environment.contexts},
              {entry.actions, environment.actions}
            ] do
          true = is_list(required) and length(required) <= 32 and Enum.uniq(required) == required
          true = Enum.all?(required, &(Schema.name?(&1) and &1 in available))
        end

        {entry.id,
         Map.merge(entry, %{
           schema: metadata.schema.declarations,
           declaration_digest: NestedTable.digest({entry.module, metadata})
         })}
      end)

    {:ok,
     %__MODULE__{
       root: environment.root,
       generation: environment.generation,
       runtime: environment.runtime,
       entries: Map.new(entries)
     }}
  rescue
    _ -> {:error, :invalid_registry}
  end

  def lookup(registry, request, allowed, boundary) do
    true = Action.keys?(request, [:id, :role, :schema_version, :generation, :props, :slots])
    true = Action.public?(request) and Action.size?(request, 65_536)
    true = request.generation == registry.generation and request.id in allowed
    true = boundary.root == registry.root and boundary.owner == registry.root
    entry = Map.fetch!(registry.entries, request.id)

    true =
      entry.visibility == :public and request.role in [:pure, :stateful] and
        entry.role == request.role

    true = request.schema_version == entry.schema_version
    {:ok, invocation} = Invocation.normalize(entry.schema, request.props, request.slots, boundary)
    {:ok, entry, invocation}
  rescue
    _ -> {:error, :unavailable_component}
  end

  def metadata(registry),
    do: %{
      version: 1,
      root: registry.root,
      generation: registry.generation,
      runtime: registry.runtime,
      entries:
        registry.entries
        |> Enum.sort()
        |> Enum.map(fn {_, entry} -> Map.delete(entry, :module) end)
    }
end
