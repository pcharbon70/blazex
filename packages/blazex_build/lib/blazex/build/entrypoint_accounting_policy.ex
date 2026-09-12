defmodule BlazeX.Build.EntryPointAccountingPolicy do
  @moduledoc "Closed-world policy for BH-06 per-entrypoint attestations."

  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @module ~r/^[A-Za-z][A-Za-z0-9_.]{0,255}$/
  @role ~r/^[a-z][a-z0-9-]{0,127}$/
  @evidence ~w(bundle_plan client_safety compatibility delivery_integrity license_inventory payload reachability runtime_closure secret_audit)

  defstruct [:id, :entrypoints, :public_roles, :private_roles, :evidence, :limits, :canonical]

  def new!(value) when is_map(value) do
    exact_keys!(
      value,
      ~w(schema_version policy_id entrypoints required_public_roles required_private_roles required_evidence limits)
    )

    unless value["schema_version"] == "1.0.0" and valid?(value["policy_id"], @id), do: invalid!()

    limits = limits!(value["limits"])
    entrypoints = entrypoints!(value["entrypoints"], limits)
    public = names!(value["required_public_roles"], @role)
    private = names!(value["required_private_roles"], @role)
    evidence = names!(value["required_evidence"], nil)

    unless MapSet.disjoint?(MapSet.new(public), MapSet.new(private)) and
             evidence == @evidence and
             length(public) + length(private) <= limits["max_artifacts"] and
             length(evidence) <= limits["max_evidence_categories"],
           do: invalid!()

    %__MODULE__{
      id: value["policy_id"],
      entrypoints: entrypoints,
      public_roles: public,
      private_roles: private,
      evidence: evidence,
      limits: limits,
      canonical: value
    }
  end

  def new!(_), do: invalid!()

  defp entrypoints!(rows, limits) when is_list(rows) and rows != [] do
    unless length(rows) <= limits["max_entrypoints"], do: invalid!()

    Enum.each(rows, fn row ->
      exact_keys!(row, ~w(id module))
      unless valid?(row["id"], @id) and valid?(row["module"], @module), do: invalid!()
    end)

    unless rows == Enum.sort_by(rows, & &1["id"]) and
             Enum.uniq_by(rows, & &1["id"]) == rows and
             Enum.uniq_by(rows, & &1["module"]) == rows,
           do: invalid!()

    rows
  end

  defp entrypoints!(_, _), do: invalid!()

  defp names!(values, regex) when is_list(values) and values != [] do
    unless Enum.all?(values, &(is_binary(&1) and (is_nil(regex) or Regex.match?(regex, &1)))) and
             values == Enum.sort(values) and length(values) == length(Enum.uniq(values)),
           do: invalid!()

    values
  end

  defp names!(_, _), do: invalid!()

  defp limits!(value) when is_map(value) do
    exact_keys!(value, ~w(max_entrypoints max_artifacts max_evidence_categories))

    unless bounded?(value["max_entrypoints"], 1, 1024) and
             bounded?(value["max_artifacts"], 1, 4096) and
             bounded?(value["max_evidence_categories"], 1, 32),
           do: invalid!()

    value
  end

  defp limits!(_), do: invalid!()

  defp exact_keys!(map, keys),
    do: unless(is_map(map) and Enum.sort(Map.keys(map)) == Enum.sort(keys), do: invalid!())

  defp valid?(value, regex), do: is_binary(value) and Regex.match?(regex, value)
  defp bounded?(value, low, high), do: is_integer(value) and value >= low and value <= high

  defp invalid!,
    do: raise(ArgumentError, "entrypoint accounting policy is malformed or outside bounds")
end
