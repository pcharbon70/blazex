defmodule BlazeX.Build.ClientSafety do
  @moduledoc "Fail-closed BH-06 classification of reachable and external dependencies."

  alias BlazeX.Build.{ClientSafetyError, ClientSafetyPolicy}

  def analyze!(reachability, inventory, %ClientSafetyPolicy{} = policy) do
    report = analyze(reachability, inventory, policy)
    if report["violations"] == [], do: report, else: raise(ClientSafetyError, report: report)
  end

  def analyze(reachability, inventory, %ClientSafetyPolicy{} = policy)
      when is_map(reachability) and is_list(inventory) do
    facts = inventory!(inventory)
    reachable = reachable!(reachability)
    external = external!(reachability)

    {modules, module_violations, used_apps, used_overrides} =
      classify_modules(reachable, facts, policy)

    {externals, external_violations, used_external} = classify_external(external, policy)
    primitive_violations = forbidden_violations(reachable, facts, policy)

    declaration_violations =
      unused_declarations(policy, used_apps, used_overrides, used_external)

    violations =
      (module_violations ++ external_violations ++ primitive_violations ++ declaration_violations)
      |> Enum.sort_by(&{&1["kind"], &1["subject"], &1["classification"], &1["reason"]})

    %{
      "schema_version" => "1.0.0",
      "policy_id" => policy.id,
      "policy_sha256" => policy.sha256,
      "modules" => modules,
      "external_modules" => externals,
      "violations" => violations,
      "summary" => %{
        "reachable_modules" => length(modules),
        "external_modules" => length(externals),
        "client_safe_modules" => Enum.count(modules, &(&1["classification"] == "client-safe")),
        "runtime_safe_externals" =>
          Enum.count(externals, &(&1["classification"] == "runtime-safe")),
        "forbidden_primitives_checked" =>
          Enum.sum(Enum.map(policy.forbidden_imports, &length(&1["arities"]))),
        "violations" => length(violations)
      }
    }
  end

  def analyze(_, _, _),
    do: raise(ArgumentError, "reachability, inventory, and policy have invalid types")

  defp inventory!(inventory) do
    unless Enum.all?(inventory, fn fact ->
             is_map(fact) and is_binary(fact["module"]) and is_binary(fact["application"]) and
               is_list(fact["imports"])
           end),
           do:
             raise(
               ArgumentError,
               "client-safety inventory is malformed or lacks application ownership"
             )

    duplicate = duplicate(inventory, & &1["module"])

    if duplicate,
      do: raise(ArgumentError, "duplicate client-safety inventory module: #{duplicate}")

    Map.new(inventory, &{&1["module"], &1})
  end

  defp reachable!(report) do
    rows = report["modules"]

    unless is_list(rows) and Enum.all?(rows, &(is_map(&1) and is_binary(&1["module"]))),
      do: raise(ArgumentError, "reachability module records are malformed")

    duplicate = duplicate(rows, & &1["module"])
    if duplicate, do: raise(ArgumentError, "duplicate reachable module: #{duplicate}")
    Enum.map(rows, & &1["module"]) |> Enum.sort()
  end

  defp external!(report) do
    rows = report["external_references"]

    unless is_list(rows) and Enum.all?(rows, &(is_map(&1) and is_binary(&1["module"]))),
      do: raise(ArgumentError, "external reference records are malformed")

    rows |> Enum.map(& &1["module"]) |> Enum.uniq() |> Enum.sort()
  end

  defp classify_modules(reachable, facts, policy) do
    Enum.reduce(reachable, {[], [], MapSet.new(), MapSet.new()}, fn module,
                                                                    {rows, violations, apps,
                                                                     overrides} ->
      fact = Map.get(facts, module)

      if fact == nil do
        violation = violation("unknown-module", module, "unknown", "missing inventory ownership")
        {rows, [violation | violations], apps, overrides}
      else
        application = fact["application"]

        case {Map.get(policy.module_overrides, module), Map.get(policy.applications, application)} do
          {%{} = rule, application_rule} ->
            row = module_row(module, application, "module", rule)
            next = maybe_violation(row, violations)
            used_apps = if application_rule, do: MapSet.put(apps, application), else: apps
            {[row | rows], next, used_apps, MapSet.put(overrides, module)}

          {nil, %{} = rule} ->
            row = module_row(module, application, "application", rule)
            next = maybe_violation(row, violations)
            {[row | rows], next, MapSet.put(apps, application), overrides}

          {nil, nil} ->
            row = %{
              "module" => module,
              "application" => application,
              "classification" => "unknown",
              "rule" => %{"kind" => "none", "id" => application},
              "reason" => "application has no client-safety rule"
            }

            {[row | rows], [violation("module", module, "unknown", row["reason"]) | violations],
             apps, overrides}
        end
      end
    end)
    |> then(fn {rows, violations, apps, overrides} ->
      {Enum.sort_by(rows, & &1["module"]), violations, apps, overrides}
    end)
  end

  defp classify_external(modules, policy) do
    Enum.reduce(modules, {[], [], MapSet.new()}, fn module, {rows, violations, used} ->
      case Map.get(policy.external_modules, module) do
        nil ->
          row = %{
            "module" => module,
            "classification" => "unknown",
            "reason" => "external module has no client-safety rule"
          }

          {[row | rows], [violation("external", module, "unknown", row["reason"]) | violations],
           used}

        rule ->
          row = %{
            "module" => module,
            "classification" => rule["classification"],
            "reason" => rule["reason"]
          }

          next = maybe_violation(Map.put(row, "subject_kind", "external"), violations)
          {[row | rows], next, MapSet.put(used, module)}
      end
    end)
    |> then(fn {rows, violations, used} ->
      {Enum.sort_by(rows, & &1["module"]), violations, used}
    end)
  end

  defp forbidden_violations(reachable, facts, policy) do
    forbidden =
      for rule <- policy.forbidden_imports,
          arity <- rule["arities"],
          into: %{},
          do: {{rule["module"], rule["function"], arity}, rule}

    reachable
    |> Enum.flat_map(fn source ->
      case Map.get(facts, source) do
        nil ->
          []

        fact ->
          Enum.flat_map(fact["imports"], fn import ->
            key = {import["module"], import["function"], import["arity"]}

            case Map.get(forbidden, key) do
              nil ->
                []

              rule ->
                [
                  violation(
                    "forbidden-import",
                    source,
                    rule["classification"],
                    "#{import["module"]}.#{import["function"]}/#{import["arity"]}: #{rule["reason"]}"
                  )
                ]
            end
          end)
      end
    end)
  end

  defp unused_declarations(policy, apps, overrides, external) do
    unused(policy.applications, apps, "unused-application-rule") ++
      unused(policy.module_overrides, overrides, "unused-module-override") ++
      unused(policy.external_modules, external, "unused-external-rule")
  end

  defp unused(rules, used, kind) do
    rules
    |> Map.keys()
    |> Enum.reject(&MapSet.member?(used, &1))
    |> Enum.map(&violation(kind, &1, "policy", "declaration did not classify the candidate"))
  end

  defp module_row(module, application, kind, rule),
    do: %{
      "module" => module,
      "application" => application,
      "classification" => rule["classification"],
      "rule" => %{"kind" => kind, "id" => rule["id"]},
      "reason" => rule["reason"]
    }

  defp maybe_violation(%{"classification" => classification} = row, violations)
       when classification in ["server-only", "native"] do
    kind = Map.get(row, "subject_kind", "module")
    subject = Map.get(row, "module")
    [violation(kind, subject, classification, row["reason"]) | violations]
  end

  defp maybe_violation(_, violations), do: violations

  defp violation(kind, subject, classification, reason),
    do: %{
      "kind" => kind,
      "subject" => subject,
      "classification" => classification,
      "reason" => reason
    }

  defp duplicate(rows, key) do
    rows
    |> Enum.group_by(key)
    |> Enum.filter(fn {_value, matches} -> length(matches) > 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
    |> List.first()
  end
end
