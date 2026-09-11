Code.require_file("../bh-05/browser_conformance/lib/cleanup_scaling.ex", __DIR__)
Code.prepend_path(Path.expand("../fixtures/browser_host/_build/dev/lib/jason/ebin", __DIR__))

defmodule BlazeX.BH05.Phase17JSON do
  def normalize(value) when value in [true, false, nil], do: value
  def normalize(value) when is_atom(value), do: Atom.to_string(value)
  def normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)

  def normalize(value) when is_map(value),
    do: Map.new(value, fn {key, item} -> {to_string(key), normalize(item)} end)

  def normalize(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.map(&normalize/1)

  def normalize(value), do: value
end

result = %{
  "schema_version" => "1.0.0",
  "phase" => 17,
  "support_state" => "unsupported",
  "factors" => BlazeX.BH05.CleanupScaling.run_factor_matrix(),
  "canonical" => BlazeX.BH05.CleanupScaling.run_subset(),
  "maximum_512" => BlazeX.BH05.CleanupScaling.run_point(:maximum, 512)
}

encoded = result |> BlazeX.BH05.Phase17JSON.normalize() |> Jason.encode!()
IO.puts("BH05_PHASE17_JSON\t" <> encoded)
