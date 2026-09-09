defmodule BlazeX.Component.ScopedContext do
  @moduledoc "Closed root-scoped public context declarations and immutable dependency snapshots."
  alias BlazeX.Component.{Action, NestedTable, RootSchedule, Schema}

  def validate(manifest) do
    true = Action.keys?(manifest, [:definitions, :owners]) and Action.public?(manifest)
    true = Action.size?(manifest, 65_536)
    true = is_map(manifest.definitions) and map_size(manifest.definitions) <= 16

    Enum.each(manifest.definitions, fn {name, d} ->
      true =
        Schema.name?(name) and
          Action.keys?(d, [
            :version,
            :schema,
            :boundary,
            :mode,
            :default,
            :doc,
            :visibility,
            :advisory
          ])

      true = d.version == 1 and Schema.host?(d.schema) and d.boundary in [:local, :host]
      true = d.mode in [:fixed, :tracked] and d.visibility == :public and is_boolean(d.advisory)
      true = is_binary(d.doc) and byte_size(d.doc) <= 1024
      true = not String.contains?(String.downcase(name), "auth") or d.advisory

      case d.default do
        :absent -> :ok
        {:present, value} -> {:ok, _} = normalize(d, value, "declaration")
        _ -> raise ArgumentError
      end
    end)

    true = is_map(manifest.owners) and map_size(manifest.owners) <= 128

    Enum.each(manifest.owners, fn {id, grants} ->
      true = Schema.name?(id) and Action.keys?(grants, [:provide, :consume])

      for names <- [grants.provide, grants.consume] do
        true = is_list(names) and length(names) <= 16 and Enum.uniq(names) == names
        true = Enum.all?(names, &Map.has_key?(manifest.definitions, &1))
      end
    end)

    :ok
  rescue
    _ -> {:error, :invalid_context_manifest}
  end

  def prepare(
        manifest,
        values,
        components,
        correlation,
        old \\ nil,
        change \\ false,
        consumer \\ nil
      ) do
    :ok = validate(manifest)
    manifest_digest = NestedTable.digest(manifest)
    true = old == nil or old.manifest_digest == manifest_digest
    true = is_list(components) and length(components) <= 128
    true = length(Enum.uniq_by(components, & &1.identity)) == length(components)

    true =
      Enum.all?(
        components,
        &(RootSchedule.identity?(&1.identity) and
            &1.identity.root == correlation.root and
            &1.identity.generation == correlation.generation)
      )

    true =
      old == nil or (old.root == correlation.root and old.generation == correlation.generation)

    true = is_list(values) and length(values) <= 32 and Action.size?(values, 65_536)
    true = Enum.uniq_by(values, &{&1.owner, &1.name}) == values
    live = Map.new(components, &{&1.identity, &1})
    revision = if old, do: old.revision + if(change, do: 1, else: 0), else: 1
    true = Action.positive?(revision)

    providers =
      Enum.map(values, fn p ->
        true = Action.keys?(p, [:owner, :name, :value]) and RootSchedule.identity?(p.owner)
        true = p.owner.root == correlation.root and p.owner.generation == correlation.generation
        c = Map.fetch!(live, p.owner)
        grant = Map.fetch!(manifest.owners, c.public_id)
        true = p.name in grant.provide and p.name in c.context_keys
        d = Map.fetch!(manifest.definitions, p.name)
        {:ok, value} = normalize(d, p.value, correlation.root)
        digest = NestedTable.digest(value)

        before =
          if old,
            do: Enum.find(old.providers, &(&1.owner == p.owner and &1.name == p.name)),
            else: nil

        true = before == nil or d.mode != :fixed or before.digest == digest

        Map.merge(p, %{
          value: value,
          digest: digest,
          revision:
            if(before != nil and before.digest == digest, do: before.revision, else: revision),
          status: :accepted
        })
      end)

    desired =
      Enum.flat_map(components, fn c ->
        grant = Map.get(manifest.owners, c.public_id, %{provide: [], consume: []})
        true = Enum.all?(c.context_keys, &(&1 in grant.provide or &1 in grant.consume))

        Enum.map(Enum.sort(grant.consume), fn name ->
          true = name in c.context_keys
          d = Map.fetch!(manifest.definitions, name)

          provider =
            providers
            |> Enum.filter(&(&1.name == name and ancestor?(&1.owner, c.identity)))
            |> Enum.max_by(&length(&1.owner.path), fn -> nil end)

          {source, value} =
            if provider,
              do: {provider.owner, provider.value},
              else: {:default, default!(d, correlation.root)}

          %{
            consumer: c.identity,
            name: name,
            provider: source,
            schema_version: d.version,
            mode: d.mode,
            value: value,
            digest: NestedTable.digest({source, value})
          }
        end)
      end)

    true = length(desired) <= 128
    old_bindings = if old, do: Map.new(old.bindings, &{{&1.consumer, &1.name}, &1}), else: %{}

    bindings =
      Enum.map(desired, fn d ->
        prior = Map.get(old_bindings, {d.consumer, d.name})
        true = prior == nil or d.mode != :fixed or prior.digest == d.digest

        if prior != nil and prior.digest != d.digest and consumer != d.consumer,
          do: prior,
          else: d
      end)

    pending =
      components
      |> Enum.map(& &1.identity)
      |> Enum.filter(fn id ->
        Enum.any?(Enum.zip(bindings, desired), fn {a, b} ->
          a.consumer == id and a.digest != b.digest
        end)
      end)

    {:ok,
     %{
       root: correlation.root,
       manifest_digest: manifest_digest,
       generation: correlation.generation,
       revision: revision,
       providers: providers,
       removed:
         if(old,
           do:
             Enum.filter(old.providers, fn p ->
               not Enum.any?(providers, &(&1.owner == p.owner and &1.name == p.name))
             end)
             |> Enum.map(&%{&1 | status: :removed, revision: revision}),
           else: []
         ),
       bindings: bindings,
       desired: desired,
       pending: pending
     }}
  rescue
    _ -> {:error, :invalid_context}
  end

  def values(scope, identity),
    do: scope.bindings |> Enum.filter(&(&1.consumer == identity)) |> Map.new(&{&1.name, &1.value})

  def provider_values(scope),
    do: Enum.map(scope.providers, &Map.take(&1, [:owner, :name, :value]))

  def stamp(scope, consumer),
    do: scope.desired |> Enum.filter(&(&1.consumer == consumer)) |> NestedTable.digest()

  def snapshot(scope),
    do: %{
      root: scope.root,
      generation: scope.generation,
      revision: scope.revision,
      providers: Enum.map(scope.providers, &Map.drop(&1, [:value])),
      removed: Enum.map(scope.removed, &Map.drop(&1, [:value])),
      subscriptions: Enum.map(scope.bindings, &Map.drop(&1, [:value])),
      pending: scope.pending
    }

  defp normalize(d, value, root) do
    with true <- Action.public?(value) and Action.size?(value, 4096),
         {:ok, normalized} <-
           Schema.normalize(d.schema, value, %{kind: d.boundary, root: root, owner: root}) do
      {:ok, normalized}
    else
      _ -> {:error, :invalid_context_value}
    end
  end

  defp default!(%{default: {:present, value}} = d, root) do
    {:ok, normalized} = normalize(d, value, root)
    normalized
  end

  defp default!(_, _), do: raise(ArgumentError)

  defp ancestor?(a, b),
    do:
      a.root == b.root and a.generation == b.generation and
        Enum.take(b.path, length(a.path)) == a.path
end
