defmodule BlazeX.Build.RuntimeClosure do
  @moduledoc "Path-free, deterministic audit of a reduced AtomVM runtime closure."

  alias BlazeX.Build.{JSON, RuntimeClosurePolicy}

  @input_keys ~w(bytes module)
  @removed_keys ~w(arity function module)
  @module ~r/^[A-Za-z][A-Za-z0-9_.]*$/
  @function ~r/^[A-Za-z_][A-Za-z0-9_!?@]*$/

  def reduce!(input_paths, output_dir, %RuntimeClosurePolicy{} = policy)
      when is_list(input_paths) and is_binary(output_dir) do
    if input_paths == [] or length(input_paths) > policy.limits["max_inputs"],
      do: invalid!("reducer input count is outside bounds")

    if File.exists?(output_dir) and File.ls!(output_dir) != [],
      do: invalid!("reducer output directory must be absent or empty")

    File.mkdir_p!(output_dir)

    inputs =
      input_paths
      |> Enum.map(&beam_input!/1)
      |> Enum.sort_by(& &1["module"])

    input_names = MapSet.new(inputs, & &1["module"])
    path_by_module = Map.new(inputs, &{&1["module"], &1["path"]})

    declared =
      policy.keep_modules ++
        policy.leave_modules ++
        policy.ignore_modules ++
        policy.drop_modules ++
        Enum.map(policy.keep_functions, & &1["module"])

    missing =
      declared |> Enum.uniq() |> Enum.reject(&MapSet.member?(input_names, &1)) |> Enum.sort()

    if missing != [],
      do: invalid!("policy modules are missing from input: #{Enum.join(missing, ", ")}")

    unless Code.ensure_loaded?(Treeshake), do: invalid!("pinned reducer is unavailable")
    verify_tool!(policy)

    opaque_modules =
      inputs
      |> Enum.reject(&analyzable?(&1["path"]))
      |> Enum.map(& &1["module"])
      |> MapSet.new()

    reachable = module_reachability!(inputs, policy)

    reducer_paths =
      inputs
      |> Enum.reject(&(&1["module"] in policy.drop_modules))
      |> Enum.filter(fn input ->
        not MapSet.member?(opaque_modules, input["module"]) or
          MapSet.member?(reachable, input["module"])
      end)
      |> Enum.map(& &1["path"])
      |> Enum.sort()

    carried_opaque =
      opaque_modules
      |> MapSet.intersection(reachable)
      |> MapSet.difference(MapSet.new(policy.drop_modules))
      |> Enum.sort()

    unless Enum.all?(carried_opaque, &Map.has_key?(path_by_module, &1)),
      do: invalid!("opaque-module classification escaped the authorized input")

    options = [
      ebin_files: reducer_paths,
      output_dir: output_dir,
      keep:
        Enum.map(policy.keep_modules, &existing_atom!/1) ++
          Enum.map(policy.keep_functions, fn row ->
            {existing_atom!(row["module"]), existing_atom!(row["function"]), row["arity"]}
          end),
      leave: Enum.map(Enum.uniq(policy.leave_modules ++ carried_opaque), &existing_atom!/1),
      ignore: Enum.map(Enum.uniq(policy.ignore_modules ++ carried_opaque), &existing_atom!/1),
      drop: Enum.map(policy.drop_modules, &existing_atom!/1),
      stub_removed_functions: false,
      stub_removed_modules: false,
      verbose: false
    ]

    stats = apply(Treeshake, :run, [options])

    output_paths =
      output_dir
      |> File.ls!()
      |> Enum.filter(&(Path.extname(&1) == ".beam"))
      |> Enum.map(&Path.join(output_dir, &1))
      |> Enum.sort()

    removed_functions = normalize_removed_functions!(stats)
    audit_inputs = Enum.map(inputs, &Map.take(&1, ~w(bytes module)))
    report = audit!(audit_inputs, output_paths, removed_functions, carried_opaque, policy)

    %{output_paths: output_paths, removed_functions: removed_functions, report: report}
  end

  def reduce!(_, _, _), do: invalid!("reducer arguments are malformed")

  def audit!(inputs, output_paths, removed_functions, %RuntimeClosurePolicy{} = policy)
      when is_list(inputs) and is_list(output_paths) and is_list(removed_functions) do
    audit!(inputs, output_paths, removed_functions, [], policy)
  end

  def audit!(_, _, _, _), do: invalid!("arguments are malformed")

  def audit!(
        inputs,
        output_paths,
        removed_functions,
        opaque_modules,
        %RuntimeClosurePolicy{} = policy
      )
      when is_list(inputs) and is_list(output_paths) and is_list(removed_functions) and
             is_list(opaque_modules) do
    inputs = inputs!(inputs, policy)
    outputs = outputs!(output_paths, policy)
    input_names = MapSet.new(inputs, & &1["module"])
    output_names = MapSet.new(outputs, & &1["module"])

    unless MapSet.subset?(output_names, input_names),
      do: invalid!("reducer output contains a module outside the authorized input closure")

    roots =
      policy.keep_modules ++
        policy.leave_modules ++ Enum.map(policy.keep_functions, & &1["module"])

    missing_roots =
      roots |> Enum.uniq() |> Enum.reject(&MapSet.member?(output_names, &1)) |> Enum.sort()

    if missing_roots != [],
      do: invalid!("retained roots are missing: #{Enum.join(missing_roots, ", ")}")

    removed_functions = removed_functions!(removed_functions, input_names, output_names, policy)
    opaque_modules = opaque_modules!(opaque_modules, inputs, outputs)
    removed_modules = input_names |> MapSet.difference(output_names) |> Enum.sort()
    before_bytes = Enum.sum(Enum.map(inputs, & &1["bytes"]))
    after_bytes = Enum.sum(Enum.map(outputs, & &1["bytes"]))

    if after_bytes >= before_bytes,
      do: invalid!("reducer did not produce a smaller runtime closure")

    %{
      "schema_version" => "1.0.0",
      "policy_id" => policy.id,
      "policy_sha256" => policy.sha256,
      "tool" => policy.tool,
      "input_set_sha256" => policy.expected_input["set_sha256"],
      "inputs" => inputs,
      "outputs" => outputs,
      "opaque_modules" => opaque_modules,
      "removed_modules" => removed_modules,
      "removed_functions" => removed_functions,
      "summary" => %{
        "before_modules" => length(inputs),
        "after_modules" => length(outputs),
        "removed_modules" => length(removed_modules),
        "before_bytes" => before_bytes,
        "after_bytes" => after_bytes,
        "removed_bytes" => before_bytes - after_bytes,
        "removed_functions" => length(removed_functions),
        "opaque_modules" => length(opaque_modules)
      },
      "complete" => true
    }
  end

  def audit!(_, _, _, _, _), do: invalid!("arguments are malformed")

  def input_set_sha256(inputs) when is_list(inputs) do
    records =
      inputs
      |> Enum.map(fn input ->
        %{
          "label" => "bundle/#{input["module"]}.beam",
          "module" => input["module"],
          "bundle_id" => "base",
          "bytes" => byte_size(input["bytes"]),
          "sha256" => digest_bytes(input["bytes"])
        }
      end)
      |> Enum.sort_by(& &1["label"])

    digest(JSON.encode!(records) <> "\n")
  end

  defp beam_input!(path) do
    unless is_binary(path) and Path.extname(path) == ".beam" and File.regular?(path),
      do: invalid!("reducer input path is not a BEAM file")

    bytes = File.read!(path)

    module =
      case :beam_lib.info(String.to_charlist(path))[:module] do
        value when is_atom(value) -> Atom.to_string(value)
        _ -> invalid!("reducer input BEAM has no module identity")
      end

    %{"module" => module, "bytes" => bytes, "path" => path}
  end

  defp analyzable?(path) do
    case :beam_lib.chunks(String.to_charlist(path), [:abstract_code, :debug_info]) do
      {:ok,
       {_module,
        [
          abstract_code: {:raw_abstract_v1, _forms},
          debug_info: _debug
        ]}} ->
        true

      {:ok,
       {_module,
        [
          abstract_code: _abstract,
          debug_info: {:debug_info_v1, :core_v1, _core}
        ]}} ->
        true

      _ ->
        false
    end
  end

  defp module_reachability!(inputs, policy) do
    inventory = MapSet.new(inputs, & &1["module"])

    imports =
      Map.new(inputs, fn input ->
        imported =
          case :beam_lib.chunks(String.to_charlist(input["path"]), [:imports]) do
            {:ok, {_module, [imports: rows]}} ->
              rows
              |> Enum.map(fn {module, _function, _arity} -> Atom.to_string(module) end)
              |> Enum.filter(&MapSet.member?(inventory, &1))
              |> MapSet.new()

            _ ->
              invalid!("could not read imports from #{input["module"]}")
          end

        {input["module"], imported}
      end)

    roots =
      policy.keep_modules ++
        policy.leave_modules ++ Enum.map(policy.keep_functions, & &1["module"])

    walk_modules(MapSet.new(roots), MapSet.new(roots), imports)
  end

  defp walk_modules(frontier, visited, imports) do
    next =
      frontier
      |> Enum.reduce(MapSet.new(), fn module, found ->
        MapSet.union(found, Map.get(imports, module, MapSet.new()))
      end)
      |> MapSet.difference(visited)

    if MapSet.size(next) == 0,
      do: visited,
      else: walk_modules(next, MapSet.union(visited, next), imports)
  end

  defp normalize_removed_functions!(%{modules_shaked: modules}) when is_map(modules) do
    modules
    |> Enum.flat_map(fn {module, functions} ->
      unless is_atom(module) and is_list(functions),
        do: invalid!("reducer returned malformed function statistics")

      Enum.map(functions, fn
        {function, arity} when is_atom(function) and is_integer(arity) ->
          %{
            "module" => Atom.to_string(module),
            "function" => Atom.to_string(function),
            "arity" => arity
          }

        _ ->
          invalid!("reducer returned malformed function statistics")
      end)
    end)
  end

  defp normalize_removed_functions!(_),
    do: invalid!("reducer returned malformed statistics")

  defp verify_tool!(policy) do
    _ = Application.load(:popcorn)
    version = Application.spec(:popcorn, :vsn)

    unless policy.tool["id"] == "popcorn" or policy.tool["id"] == "popcorn-treeshake",
      do: invalid!("policy does not name the pinned Popcorn reducer")

    unless version && to_string(version) == policy.tool["version"],
      do: invalid!("loaded reducer version does not match policy")
  end

  defp existing_atom!(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError ->
      invalid!("policy name is not present in the authorized BEAM inventory: #{value}")
  end

  defp inputs!(inputs, policy) do
    if length(inputs) != policy.expected_input["modules"] or
         length(inputs) > policy.limits["max_inputs"],
       do: invalid!("input module count does not match the authorized closure")

    material =
      inputs
      |> Enum.map(fn input ->
        unless is_map(input) and Map.keys(input) |> Enum.sort() == @input_keys and
                 valid_name?(input["module"], @module, policy) and is_binary(input["bytes"]),
               do: invalid!("input row is malformed")

        input
      end)

    unless input_set_sha256(material) == policy.expected_input["set_sha256"],
      do: invalid!("input set does not match the authorized closure")

    rows =
      material
      |> Enum.map(&record(&1["module"], &1["bytes"]))
      |> Enum.sort_by(& &1["module"])

    unique!(rows, "input")
    rows
  end

  defp outputs!(paths, policy) do
    if paths == [] or length(paths) > policy.limits["max_outputs"],
      do: invalid!("output module count is outside bounds")

    rows =
      Enum.map(paths, fn path ->
        unless is_binary(path) and Path.extname(path) == ".beam" and File.regular?(path),
          do: invalid!("output path is not a BEAM file")

        bytes = File.read!(path)

        module =
          case :beam_lib.info(String.to_charlist(path))[:module] do
            value when is_atom(value) -> Atom.to_string(value)
            _ -> invalid!("output BEAM has no module identity")
          end

        unless valid_name?(module, @module, policy), do: invalid!("output module name is invalid")
        record(module, bytes)
      end)
      |> Enum.sort_by(& &1["module"])

    unique!(rows, "output")
  end

  defp removed_functions!(rows, inputs, outputs, policy) do
    if length(rows) > policy.limits["max_removed_functions"],
      do: invalid!("removed function count exceeds explicit limit")

    normalized =
      Enum.map(rows, fn row ->
        unless is_map(row) and Map.keys(row) |> Enum.sort() == @removed_keys and
                 valid_name?(row["module"], @module, policy) and
                 valid_name?(row["function"], @function, policy) and
                 is_integer(row["arity"]) and row["arity"] in 0..255 and
                 MapSet.member?(inputs, row["module"]) and MapSet.member?(outputs, row["module"]),
               do: invalid!("removed function row is malformed or has invalid ownership")

        row
      end)
      |> Enum.sort_by(&{&1["module"], &1["function"], &1["arity"]})

    if length(normalized) !=
         length(Enum.uniq_by(normalized, &{&1["module"], &1["function"], &1["arity"]})),
       do: invalid!("removed function rows are duplicated")

    normalized
  end

  defp opaque_modules!(modules, inputs, outputs) do
    if modules != Enum.sort(modules) or length(modules) != length(Enum.uniq(modules)),
      do: invalid!("opaque module list is not sorted and unique")

    input_by_module = Map.new(inputs, &{&1["module"], &1})
    output_by_module = Map.new(outputs, &{&1["module"], &1})

    Enum.each(modules, fn module ->
      unless input_by_module[module] && output_by_module[module] &&
               input_by_module[module] == output_by_module[module],
             do: invalid!("opaque module was removed or modified: #{module}")
    end)

    modules
  end

  defp record(module, bytes),
    do: %{"module" => module, "bytes" => byte_size(bytes), "sha256" => digest_bytes(bytes)}

  defp unique!(rows, label) do
    if length(rows) != length(Enum.uniq_by(rows, & &1["module"])),
      do: invalid!("#{label} modules are duplicated")

    rows
  end

  defp valid_name?(value, regex, policy),
    do:
      is_binary(value) and byte_size(value) <= policy.limits["max_name_length"] and
        Regex.match?(regex, value)

  defp digest_bytes(bytes), do: digest(bytes)
  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  defp invalid!(reason), do: raise(ArgumentError, "runtime closure audit failed: #{reason}")
end
