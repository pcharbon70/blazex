defmodule BlazeX.Build.DeliveryIntegrityPolicy do
  @moduledoc "Closed-world integrity and Cache-Control policy for delivery metadata."

  @id ~r/^[a-z][a-z0-9._\/-]{0,127}$/
  @role ~r/^[a-z][a-z0-9-]{0,127}$/
  @cache_values ["no-store", "public, max-age=31536000, immutable"]
  @cardinalities ["exactly-one", "one-or-more"]

  defstruct [:id, :algorithm, :roles, :limits, :canonical]

  def new!(value) when is_map(value) do
    require_keys!(value, ~w(schema_version policy_id integrity_algorithm roles limits))

    unless value["schema_version"] == "1.0.0" and valid?(value["policy_id"], @id) and
             value["integrity_algorithm"] == "sha384",
           do: invalid!()

    limits = limits!(value["limits"])
    roles = roles!(value["roles"], limits)

    %__MODULE__{
      id: value["policy_id"],
      algorithm: value["integrity_algorithm"],
      roles: roles,
      limits: limits,
      canonical: value
    }
  end

  def new!(_), do: invalid!()

  defp roles!(roles, limits) when is_map(roles) and map_size(roles) > 0 do
    Enum.each(roles, fn {role, declaration} ->
      require_keys!(declaration, ~w(cache_control cardinality))

      unless valid?(role, @role) and byte_size(role) <= limits["max_role_length"] and
               declaration["cache_control"] in @cache_values and
               declaration["cardinality"] in @cardinalities,
             do: invalid!()
    end)

    roles
  end

  defp roles!(_, _), do: invalid!()

  defp limits!(value) when is_map(value) do
    require_keys!(value, ~w(max_artifacts max_total_bytes max_role_length))

    unless bounded?(value["max_artifacts"], 1, 4096) and
             bounded?(value["max_total_bytes"], 1, 1_073_741_824) and
             bounded?(value["max_role_length"], 1, 128),
           do: invalid!()

    value
  end

  defp limits!(_), do: invalid!()

  defp require_keys!(map, keys) do
    unless is_map(map) and Enum.sort(Map.keys(map)) == Enum.sort(keys), do: invalid!()
  end

  defp valid?(value, regex), do: is_binary(value) and Regex.match?(regex, value)
  defp bounded?(value, low, high), do: is_integer(value) and value >= low and value <= high

  defp invalid!,
    do: raise(ArgumentError, "delivery integrity policy is malformed or outside bounds")
end
