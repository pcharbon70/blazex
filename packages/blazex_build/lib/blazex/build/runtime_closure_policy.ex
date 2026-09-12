defmodule BlazeX.Build.RuntimeClosurePolicy do
  @moduledoc "Validated, closed-world policy for audited runtime-closure reduction."

  alias BlazeX.Build.JSON

  @enforce_keys [
    :id,
    :sha256,
    :tool,
    :expected_input,
    :keep_modules,
    :keep_functions,
    :leave_modules,
    :ignore_modules,
    :drop_modules,
    :limits
  ]
  defstruct @enforce_keys

  @top ~w(drop_modules expected_input ignore_modules keep_functions keep_modules leave_modules limits policy_id schema_version tool)
  @tool ~w(id lock_sha256 version)
  @expected ~w(modules set_sha256)
  @function ~w(arity function module)
  @limits ~w(max_inputs max_name_length max_outputs max_removed_functions)
  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @module ~r/^[A-Za-z][A-Za-z0-9_.]*$/
  @function_name ~r/^[A-Za-z_][A-Za-z0-9_!?@]*$/
  @sha256 ~r/^[0-9a-f]{64}$/
  @ceilings %{
    "max_inputs" => 10_000,
    "max_name_length" => 256,
    "max_outputs" => 10_000,
    "max_removed_functions" => 1_000_000
  }

  def new!(attributes) when is_map(attributes) do
    exact!(attributes, @top, "runtime closure policy")

    unless attributes["schema_version"] == "1.0.0" and valid?(attributes["policy_id"], @id),
      do: invalid!("identity")

    tool = tool!(attributes["tool"])
    expected = expected!(attributes["expected_input"])
    limits = limits!(attributes["limits"])
    keep_modules = modules!(attributes["keep_modules"], limits, "keep modules", false)
    keep_functions = functions!(attributes["keep_functions"], limits)
    leave_modules = modules!(attributes["leave_modules"], limits, "leave modules", false)
    ignore_modules = modules!(attributes["ignore_modules"], limits, "ignore modules", true)
    drop_modules = modules!(attributes["drop_modules"], limits, "drop modules", true)

    roots = keep_modules ++ leave_modules ++ Enum.map(keep_functions, & &1["module"])

    if Enum.any?(roots, &(&1 in drop_modules)),
      do: invalid!("a retained root cannot also be dropped")

    overlaps = [
      {keep_modules, ignore_modules},
      {drop_modules, ignore_modules}
    ]

    if Enum.any?(overlaps, fn {left, right} ->
         not MapSet.disjoint?(MapSet.new(left), MapSet.new(right))
       end),
       do: invalid!("declarations overlap outside the explicit leave-and-ignore exception")

    normalized = %{
      "schema_version" => "1.0.0",
      "policy_id" => attributes["policy_id"],
      "tool" => tool,
      "expected_input" => expected,
      "keep_modules" => keep_modules,
      "keep_functions" => keep_functions,
      "leave_modules" => leave_modules,
      "ignore_modules" => ignore_modules,
      "drop_modules" => drop_modules,
      "limits" => limits
    }

    struct!(__MODULE__,
      id: attributes["policy_id"],
      sha256: digest(normalized),
      tool: tool,
      expected_input: expected,
      keep_modules: keep_modules,
      keep_functions: keep_functions,
      leave_modules: leave_modules,
      ignore_modules: ignore_modules,
      drop_modules: drop_modules,
      limits: limits
    )
  end

  def new!(_), do: invalid!("must be a map")

  defp tool!(value) when is_map(value) do
    exact!(value, @tool, "runtime closure tool")

    unless valid?(value["id"], @id) and is_binary(value["version"]) and
             byte_size(value["version"]) in 1..64 and valid?(value["lock_sha256"], @sha256),
           do: invalid!("tool identity")

    value
  end

  defp tool!(_), do: invalid!("tool")

  defp expected!(value) when is_map(value) do
    exact!(value, @expected, "runtime closure expected input")

    unless is_integer(value["modules"]) and value["modules"] in 1..10_000 and
             valid?(value["set_sha256"], @sha256),
           do: invalid!("expected input")

    value
  end

  defp expected!(_), do: invalid!("expected input")

  defp functions!(values, limits) when is_list(values) and values != [] do
    rows =
      Enum.map(values, fn value ->
        unless is_map(value), do: invalid!("keep function")
        exact!(value, @function, "runtime closure keep function")

        unless module?(value["module"], limits) and function?(value["function"], limits) and
                 is_integer(value["arity"]) and value["arity"] in 0..255,
               do: invalid!("keep function")

        value
      end)
      |> Enum.sort_by(&{&1["module"], &1["function"], &1["arity"]})

    unique!(rows, &{&1["module"], &1["function"], &1["arity"]}, "keep function")
  end

  defp functions!(_, _), do: invalid!("keep functions must be a non-empty list")

  defp modules!(values, limits, label, allow_empty) when is_list(values) do
    if not allow_empty and values == [], do: invalid!("#{label} must be non-empty")
    unless Enum.all?(values, &module?(&1, limits)), do: invalid!(label)
    values |> unique!(& &1, label) |> Enum.sort()
  end

  defp modules!(_, _, label, _), do: invalid!(label)

  defp limits!(limits) when is_map(limits) do
    exact!(limits, @limits, "runtime closure limits")

    unless Enum.all?(@ceilings, fn {key, ceiling} ->
             is_integer(limits[key]) and limits[key] in 1..ceiling
           end) and limits["max_outputs"] <= limits["max_inputs"],
           do: invalid!("limits")

    limits
  end

  defp limits!(_), do: invalid!("limits")

  defp module?(value, limits),
    do:
      is_binary(value) and byte_size(value) <= limits["max_name_length"] and
        valid?(value, @module)

  defp function?(value, limits),
    do:
      is_binary(value) and byte_size(value) <= limits["max_name_length"] and
        valid?(value, @function_name)

  defp unique!(rows, key, label) do
    if Enum.any?(Enum.group_by(rows, key), fn {_, matches} -> length(matches) > 1 end),
      do: invalid!("duplicate #{label}")

    rows
  end

  defp exact!(map, keys, label) do
    unless Map.keys(map) |> Enum.sort() == Enum.sort(keys),
      do: invalid!("#{label} has missing or unknown fields")
  end

  defp valid?(value, regex), do: is_binary(value) and Regex.match?(regex, value)

  defp digest(value),
    do: :crypto.hash(:sha256, JSON.encode!(value) <> "\n") |> Base.encode16(case: :lower)

  defp invalid!(reason), do: raise(ArgumentError, "runtime closure policy is invalid: #{reason}")
end
