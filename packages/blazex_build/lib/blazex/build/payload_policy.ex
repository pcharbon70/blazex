defmodule BlazeX.Build.PayloadPolicy do
  @moduledoc "Closed-world public payload and build-evidence policy."

  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @name ~r/^[a-z][a-z0-9-]{0,63}$/
  @metrics ~w(decoded_bytes brotli_bytes source_map_bytes)
  @directions ~w(at-most exactly)
  @exposures ~w(public private-build-evidence)
  @required_roles ~w(build-manifest document runtime-module runtime-wasm application-bundle browser-host feature-bundle reachability-report client-safety-report compatibility-report secret-audit-report license-inventory-report bundle-plan-report)
  @optional_roles ~w(runtime-closure-report)

  defstruct [:id, :compression, :roles, :budgets, :limits, :canonical]

  def new!(value) when is_map(value) do
    require_keys!(value, ~w(schema_version policy_id compression roles budgets limits))
    if value["schema_version"] != "1.0.0" or not valid?(value["policy_id"], @id), do: invalid!()
    compression = compression!(value["compression"])
    limits = limits!(value["limits"])
    roles = roles!(value["roles"], limits)
    budgets = budgets!(value["budgets"], roles)

    %__MODULE__{
      id: value["policy_id"],
      compression: compression,
      roles: roles,
      budgets: budgets,
      limits: limits,
      canonical: value
    }
  end

  def new!(_), do: invalid!()

  defp compression!(
         %{
           "algorithm" => "brotli",
           "implementation" => "node-zlib",
           "quality" => 11,
           "repetitions" => repetitions
         } = value
       )
       when map_size(value) == 4 and repetitions >= 3 and repetitions <= 10,
       do: value

  defp compression!(_), do: invalid!()

  defp limits!(value) when is_map(value) do
    require_keys!(value, ~w(max_artifacts max_public_bytes max_role_length max_owner_length))

    if map_size(value) != 4 or not bounded?(value["max_artifacts"], 1, 4096) or
         not bounded?(value["max_public_bytes"], 1, 1_073_741_824) or
         not bounded?(value["max_role_length"], 1, 128) or
         not bounded?(value["max_owner_length"], 1, 128),
       do: invalid!()

    value
  end

  defp limits!(_), do: invalid!()

  defp roles!(roles, limits) when is_map(roles) do
    keys = Map.keys(roles)

    if not MapSet.subset?(MapSet.new(@required_roles), MapSet.new(keys)) or
         not MapSet.subset?(MapSet.new(keys), MapSet.new(@required_roles ++ @optional_roles)) or
         map_size(roles) > limits["max_artifacts"],
       do: invalid!()

    Enum.each(roles, fn {role, declaration} ->
      unless valid?(role, @name) and byte_size(role) <= limits["max_role_length"] and
               is_map(declaration) and map_size(declaration) == 2 and
               valid?(declaration["owner"], @name) and
               byte_size(declaration["owner"]) <= limits["max_owner_length"] and
               declaration["exposure"] in @exposures,
             do: invalid!()
    end)

    roles
  end

  defp roles!(_, _), do: invalid!()

  defp budgets!(budgets, roles) when is_list(budgets) and budgets != [] do
    owners =
      roles |> Map.values() |> Enum.map(& &1["owner"]) |> MapSet.new() |> MapSet.put("public")

    Enum.each(budgets, fn budget ->
      require_keys!(budget, ~w(id owner metric direction threshold))

      unless map_size(budget) == 5 and valid?(budget["id"], @name) and
               MapSet.member?(owners, budget["owner"]) and budget["metric"] in @metrics and
               budget["direction"] in @directions and
               is_integer(budget["threshold"]) and budget["threshold"] >= 0,
             do: invalid!()
    end)

    ids = Enum.map(budgets, & &1["id"])
    if ids != Enum.sort(ids) or length(ids) != length(Enum.uniq(ids)), do: invalid!()
    budgets
  end

  defp budgets!(_, _), do: invalid!()

  defp require_keys!(map, keys) do
    unless is_map(map) and Map.keys(map) |> Enum.sort() == Enum.sort(keys), do: invalid!()
  end

  defp valid?(value, regex), do: is_binary(value) and Regex.match?(regex, value)
  defp bounded?(value, low, high), do: is_integer(value) and value >= low and value <= high
  defp invalid!, do: raise(ArgumentError, "payload policy is malformed or outside bounds")
end
