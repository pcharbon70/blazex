defmodule BlazeX.Build.SecretAudit do
  @moduledoc "Path-free, value-redacted fixed-signature audit for BH-06 inputs."
  alias BlazeX.Build.{JSON, SecretAuditError, SecretPolicy}
  @label ~r/^[a-zA-Z0-9][a-zA-Z0-9._\/-]{0,255}$/
  @max_config_bytes 1_048_576
  @max_depth 16

  def analyze!(inputs, public_config, %SecretPolicy{} = policy) do
    report = analyze(inputs, public_config, policy)
    if report["clean"], do: report, else: raise(SecretAuditError, report: report)
  end

  def analyze(inputs, public_config, %SecretPolicy{} = policy) when is_list(inputs) do
    inputs = inputs!(inputs, policy.limits)
    config = config!(public_config)
    config_body = JSON.encode!(config)

    if byte_size(config_body) > @max_config_bytes,
      do: raise(ArgumentError, "public configuration exceeds byte limit")

    literal_findings =
      Enum.flat_map(
        inputs ++ [%{"label" => "public-config", "bytes" => config_body}],
        &scan_literals(&1, policy.literal_rules)
      )

    findings =
      (literal_findings ++ scan_keys(config, policy.key_fragments))
      |> Enum.sort_by(&{&1["kind"], &1["subject"], &1["rule_id"], Map.get(&1, "offset", -1)})

    if length(findings) > policy.limits["max_findings"],
      do: raise(ArgumentError, "secret audit finding count exceeds explicit limit")

    records =
      Enum.map(
        inputs,
        &%{
          "label" => &1["label"],
          "bytes" => byte_size(&1["bytes"]),
          "sha256" => digest(&1["bytes"])
        }
      )

    %{
      "schema_version" => "1.0.0",
      "policy_id" => policy.id,
      "policy_sha256" => policy.sha256,
      "public_config_sha256" => digest(config_body <> "\n"),
      "inputs" => records,
      "findings" => findings,
      "summary" => %{
        "inputs" => length(records),
        "input_bytes" => Enum.sum(Enum.map(records, & &1["bytes"])),
        "literal_rules" => length(policy.literal_rules),
        "key_fragments" => length(policy.key_fragments),
        "findings" => length(findings)
      },
      "clean" => findings == []
    }
  end

  def analyze(_, _, _), do: raise(ArgumentError, "secret audit inputs or policy are invalid")

  defp inputs!(inputs, limits) do
    if length(inputs) > limits["max_inputs"],
      do: raise(ArgumentError, "secret audit input count exceeds explicit limit")

    rows =
      inputs
      |> Enum.map(fn input ->
        unless is_map(input) and Map.keys(input) |> Enum.sort() == ~w(bytes label) and
                 is_binary(input["label"]) and Regex.match?(@label, input["label"]) and
                 is_binary(input["bytes"]),
               do: raise(ArgumentError, "secret audit input is malformed")

        if byte_size(input["bytes"]) > limits["max_input_bytes"],
          do: raise(ArgumentError, "secret audit input exceeds per-input byte limit")

        input
      end)
      |> Enum.sort_by(& &1["label"])

    if rows |> Enum.map(& &1["label"]) |> Enum.uniq() |> length() != length(rows),
      do: raise(ArgumentError, "duplicate secret audit input label")

    if Enum.sum(Enum.map(rows, &byte_size(&1["bytes"]))) > limits["max_total_bytes"],
      do: raise(ArgumentError, "secret audit inputs exceed aggregate byte limit")

    rows
  end

  defp config!(config) when is_map(config), do: tap(config, &validate_json!(&1, 0))
  defp config!(_), do: raise(ArgumentError, "public configuration must be a map")

  defp validate_json!(_, depth) when depth > @max_depth,
    do: raise(ArgumentError, "public configuration exceeds nesting limit")

  defp validate_json!(value, depth) when is_map(value),
    do:
      Enum.each(value, fn {key, item} ->
        unless is_binary(key) and byte_size(key) in 1..256,
          do: raise(ArgumentError, "public configuration key is invalid")

        validate_json!(item, depth + 1)
      end)

  defp validate_json!(value, depth) when is_list(value),
    do: Enum.each(value, &validate_json!(&1, depth + 1))

  defp validate_json!(value, _) when is_binary(value) and byte_size(value) <= @max_config_bytes,
    do: :ok

  defp validate_json!(value, _)
       when is_integer(value) or is_float(value) or is_boolean(value) or is_nil(value),
       do: :ok

  defp validate_json!(_, _),
    do: raise(ArgumentError, "public configuration contains an unsupported value")

  defp scan_literals(input, rules),
    do:
      Enum.flat_map(rules, fn rule ->
        Enum.map(:binary.matches(input["bytes"], rule["literal"]), fn {offset, _} ->
          %{
            "kind" => "literal",
            "subject" => input["label"],
            "rule_id" => rule["id"],
            "offset" => offset
          }
        end)
      end)

  defp scan_keys(config, fragments), do: scan_keys(config, fragments, [])

  defp scan_keys(value, fragments, path) when is_map(value),
    do:
      Enum.flat_map(value, fn {key, item} ->
        subject = Enum.join(path ++ [key], ".")

        found =
          fragments
          |> Enum.filter(&String.contains?(String.downcase(key), &1))
          |> Enum.map(
            &%{"kind" => "config-key", "subject" => subject, "rule_id" => "key-fragment/#{&1}"}
          )

        found ++ scan_keys(item, fragments, path ++ [key])
      end)

  defp scan_keys(value, fragments, path) when is_list(value),
    do:
      value
      |> Enum.with_index()
      |> Enum.flat_map(fn {item, index} ->
        scan_keys(item, fragments, path ++ [Integer.to_string(index)])
      end)

  defp scan_keys(_, _, _), do: []
  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
