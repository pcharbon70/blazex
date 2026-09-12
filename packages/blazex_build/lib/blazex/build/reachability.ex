defmodule BlazeX.Build.Reachability do
  @moduledoc "Deterministic entrypoint-rooted traversal over normalized BEAM facts."

  alias BlazeX.Build.ClientEntryPoint

  @dynamic MapSet.new([
             {"erlang", "apply", 2},
             {"erlang", "apply", 3}
           ])

  def analyze!(entrypoints, inventory, options \\ [])

  def analyze!(entrypoints, inventory, options)
      when is_list(entrypoints) and is_list(inventory) and is_list(options) do
    entries = normalize_entries!(entrypoints)
    modules = index_inventory!(inventory)
    allowances = validate_allowances!(Keyword.get(options, :allow_dynamic, %{}))
    ensure_roots!(entries, modules)

    paths =
      entries
      |> Enum.flat_map(fn entry ->
        traverse(entry.module, modules)
        |> Enum.map(fn {module, chain} -> {module, entry.id, chain} end)
      end)
      |> Enum.group_by(&elem(&1, 0))
      |> Map.new(fn {module, candidates} ->
        best =
          Enum.min_by(candidates, fn {_module, entry, chain} -> {length(chain), entry, chain} end)

        {module, %{entrypoint: elem(best, 1), chain: elem(best, 2)}}
      end)

    reachable = paths |> Map.keys() |> Enum.sort()
    dynamic = dynamic_imports(reachable, modules)
    enforce_dynamic!(dynamic, allowances)

    module_rows =
      Enum.map(reachable, fn module ->
        fact = Map.fetch!(modules, module)
        reason = Map.fetch!(paths, module)

        %{
          "module" => module,
          "sha256" => fact["sha256"],
          "entrypoint" => reason.entrypoint,
          "reason_chain" => reason.chain,
          "known_imports" => known_imports(fact, modules)
        }
      end)

    external = external_references(reachable, modules)
    unused = modules |> Map.keys() |> Enum.reject(&Map.has_key?(paths, &1)) |> Enum.sort()

    %{
      "schema_version" => "1.0.0",
      "entrypoints" => Enum.map(entries, &%{"id" => &1.id, "module" => &1.module}),
      "modules" => module_rows,
      "external_references" => external,
      "unused_modules" => unused,
      "dynamic_allowances" => Enum.map(dynamic, &dynamic_row(&1, allowances)),
      "summary" => %{
        "entrypoints" => length(entries),
        "inventory_modules" => map_size(modules),
        "reachable_modules" => length(reachable),
        "known_edges" => Enum.sum(Enum.map(module_rows, &length(&1["known_imports"]))),
        "external_references" => length(external),
        "unused_modules" => length(unused),
        "dynamic_allowances" => length(dynamic)
      }
    }
  end

  def analyze!(_, _, _),
    do: raise(ArgumentError, "entrypoints, inventory, and options must be lists")

  defp normalize_entries!(entries) do
    unless Enum.all?(entries, &match?(%ClientEntryPoint{}, &1)),
      do: raise(ArgumentError, "all entrypoints must be validated ClientEntryPoint records")

    duplicate_ids = duplicates(entries, & &1.id)
    duplicate_modules = duplicates(entries, & &1.module)

    if duplicate_ids != [],
      do: raise(ArgumentError, "duplicate entrypoint ids: #{Enum.join(duplicate_ids, ", ")}")

    if duplicate_modules != [],
      do:
        raise(
          ArgumentError,
          "duplicate entrypoint modules: #{Enum.join(duplicate_modules, ", ")}"
        )

    Enum.sort_by(entries, &{&1.id, &1.module})
  end

  defp duplicates(values, key) do
    values
    |> Enum.group_by(key)
    |> Enum.filter(fn {_value, rows} -> length(rows) > 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  defp index_inventory!(inventory) do
    unless Enum.all?(inventory, &valid_fact?/1),
      do: raise(ArgumentError, "inventory contains malformed module facts")

    duplicates = duplicates(inventory, & &1["module"])

    if duplicates != [],
      do: raise(ArgumentError, "duplicate inventory modules: #{Enum.join(duplicates, ", ")}")

    Map.new(inventory, &{&1["module"], &1})
  end

  defp valid_fact?(fact),
    do:
      is_map(fact) and is_binary(fact["module"]) and is_binary(fact["sha256"]) and
        is_list(fact["imports"])

  defp ensure_roots!(entries, modules) do
    missing = entries |> Enum.reject(&Map.has_key?(modules, &1.module)) |> Enum.map(& &1.module)

    if missing != [],
      do:
        raise(
          ArgumentError,
          "entrypoint modules missing from inventory: #{Enum.join(missing, ", ")}"
        )
  end

  defp traverse(root, modules), do: traverse([{root, [root]}], modules, %{})
  defp traverse([], _modules, visited), do: visited

  defp traverse([{module, chain} | rest], modules, visited) do
    if Map.has_key?(visited, module) do
      traverse(rest, modules, visited)
    else
      next =
        modules
        |> Map.fetch!(module)
        |> known_imports(modules)
        |> Enum.reject(&Map.has_key?(visited, &1))
        |> Enum.map(&{&1, chain ++ [&1]})

      traverse(rest ++ next, modules, Map.put(visited, module, chain))
    end
  end

  defp known_imports(fact, modules) do
    fact["imports"]
    |> Enum.map(& &1["module"])
    |> Enum.filter(&Map.has_key?(modules, &1))
    |> Enum.reject(&(&1 == fact["module"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp external_references(reachable, modules) do
    reachable
    |> Enum.flat_map(fn source ->
      modules[source]["imports"]
      |> Enum.reject(&Map.has_key?(modules, &1["module"]))
      |> Enum.map(&Map.put(&1, "from", source))
    end)
    |> Enum.uniq()
    |> Enum.sort_by(&{&1["from"], &1["module"], &1["function"], &1["arity"]})
  end

  defp dynamic_imports(reachable, modules) do
    reachable
    |> Enum.flat_map(fn source ->
      modules[source]["imports"]
      |> Enum.filter(&MapSet.member?(@dynamic, {&1["module"], &1["function"], &1["arity"]}))
      |> Enum.map(&Map.put(&1, "from", source))
    end)
    |> Enum.uniq()
    |> Enum.sort_by(&{&1["from"], &1["function"], &1["arity"]})
  end

  defp validate_allowances!(allowances) when is_map(allowances) do
    unless Enum.all?(allowances, fn {module, reason} ->
             is_binary(module) and is_binary(reason) and byte_size(reason) in 1..256
           end),
           do: raise(ArgumentError, "dynamic allowances require bounded module-string reasons")

    allowances
  end

  defp validate_allowances!(_), do: raise(ArgumentError, "dynamic allowances must be a map")

  defp enforce_dynamic!(dynamic, allowances) do
    undeclared =
      dynamic
      |> Enum.map(& &1["from"])
      |> Enum.uniq()
      |> Enum.reject(&Map.has_key?(allowances, &1))

    unused = Map.keys(allowances) -- Enum.map(dynamic, & &1["from"])

    if undeclared != [],
      do: raise(ArgumentError, "undeclared dynamic dispatch: #{Enum.join(undeclared, ", ")}")

    if unused != [],
      do: raise(ArgumentError, "unused dynamic allowances: #{Enum.join(Enum.sort(unused), ", ")}")
  end

  defp dynamic_row(import, allowances),
    do: Map.put(import, "reason", Map.fetch!(allowances, import["from"]))
end
