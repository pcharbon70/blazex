defmodule BlazeX.Build.ClientSafetyPolicy do
  @moduledoc "Validated exact-match policy for BH-06 client dependency classification."

  alias BlazeX.Build.JSON

  @enforce_keys [
    :id,
    :sha256,
    :applications,
    :module_overrides,
    :external_modules,
    :forbidden_imports
  ]
  defstruct @enforce_keys

  @top_keys ~w(schema_version policy_id applications module_overrides external_modules forbidden_imports)
  @reachable ~w(client-safe server-only native)
  @external ~w(runtime-safe server-only native)
  @forbidden ~w(server-only native)
  @policy_id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @application_id ~r/^[a-z][a-z0-9_]{0,63}$/
  @module_id ~r/^[A-Za-z][A-Za-z0-9_.]{0,254}$/

  def new!(attributes) when is_map(attributes) do
    unless Map.keys(attributes) |> Enum.sort() == Enum.sort(@top_keys),
      do: raise(ArgumentError, "client-safety policy has missing or unknown fields")

    unless attributes["schema_version"] == "1.0.0" and
             bounded?(attributes["policy_id"], @policy_id),
           do: raise(ArgumentError, "client-safety policy identity is invalid")

    applications = rules!(attributes["applications"], "application", @application_id, @reachable)
    overrides = rules!(attributes["module_overrides"], "module override", @module_id, @reachable)
    external = rules!(attributes["external_modules"], "external module", @module_id, @external)
    forbidden = forbidden!(attributes["forbidden_imports"])

    normalized = %{
      "schema_version" => "1.0.0",
      "policy_id" => attributes["policy_id"],
      "applications" => Map.values(applications) |> Enum.sort_by(& &1["id"]),
      "module_overrides" => Map.values(overrides) |> Enum.sort_by(& &1["id"]),
      "external_modules" => Map.values(external) |> Enum.sort_by(& &1["id"]),
      "forbidden_imports" => forbidden
    }

    %__MODULE__{
      id: attributes["policy_id"],
      sha256: digest(JSON.encode!(normalized) <> "\n"),
      applications: applications,
      module_overrides: overrides,
      external_modules: external,
      forbidden_imports: forbidden
    }
  end

  def new!(_), do: raise(ArgumentError, "client-safety policy must be a map")

  defp rules!(rows, label, id_pattern, classifications) when is_list(rows) do
    normalized =
      Enum.map(rows, fn row ->
        unless is_map(row) and Map.keys(row) |> Enum.sort() == ~w(classification id reason),
          do: raise(ArgumentError, "#{label} rule is malformed")

        unless bounded?(row["id"], id_pattern) and row["classification"] in classifications and
                 reason?(row["reason"]),
               do: raise(ArgumentError, "#{label} rule is invalid")

        row
      end)

    duplicate = duplicate(normalized, & &1["id"])
    if duplicate, do: raise(ArgumentError, "duplicate #{label} rule: #{duplicate}")
    Map.new(normalized, &{&1["id"], &1})
  end

  defp rules!(_, label, _, _), do: raise(ArgumentError, "#{label} rules must be a list")

  defp forbidden!(rows) when is_list(rows) do
    normalized =
      Enum.map(rows, fn row ->
        unless is_map(row) and
                 Map.keys(row) |> Enum.sort() ==
                   ~w(arities classification function module reason),
               do: raise(ArgumentError, "forbidden import rule is malformed")

        arities = row["arities"]

        unless bounded?(row["module"], @module_id) and bounded?(row["function"], @module_id) and
                 row["classification"] in @forbidden and reason?(row["reason"]) and
                 is_list(arities) and arities != [] and arities == Enum.sort(Enum.uniq(arities)) and
                 Enum.all?(arities, &(is_integer(&1) and &1 in 0..255)),
               do: raise(ArgumentError, "forbidden import rule is invalid")

        row
      end)
      |> Enum.sort_by(&{&1["module"], &1["function"], &1["arities"]})

    collisions =
      normalized
      |> Enum.flat_map(fn row ->
        Enum.map(row["arities"], &{row["module"], row["function"], &1})
      end)
      |> duplicate(& &1)

    if collisions,
      do: raise(ArgumentError, "duplicate forbidden import rule: #{inspect(collisions)}")

    normalized
  end

  defp forbidden!(_), do: raise(ArgumentError, "forbidden import rules must be a list")

  defp duplicate(rows, key) do
    rows
    |> Enum.group_by(key)
    |> Enum.filter(fn {_value, matches} -> length(matches) > 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
    |> List.first()
  end

  defp bounded?(value, pattern), do: is_binary(value) and Regex.match?(pattern, value)

  defp reason?(value),
    do:
      is_binary(value) and byte_size(value) in 1..256 and
        not String.contains?(value, ["\n", "\r"])

  defp digest(body), do: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
end
