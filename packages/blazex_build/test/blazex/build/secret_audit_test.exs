defmodule BlazeX.Build.SecretAuditTest do
  use ExUnit.Case, async: true
  alias BlazeX.Build.{SecretAudit, SecretAuditError, SecretPolicy}

  test "accounts for clean unordered inputs deterministically" do
    one =
      SecretAudit.analyze!(
        [input("z.js", "safe"), input("a.beam", <<1, 2>>)],
        %{"theme" => "dark"},
        policy()
      )

    two =
      SecretAudit.analyze!(
        [input("a.beam", <<1, 2>>), input("z.js", "safe")],
        %{"theme" => "dark"},
        policy(reverse: true)
      )

    assert one == two
    assert Enum.map(one["inputs"], & &1["label"]) == ["a.beam", "z.js"]
  end

  test "rejects literals with value-redacted diagnostics" do
    error =
      assert_raise SecretAuditError, fn ->
        SecretAudit.analyze!([input("app.beam", "prefix ghp_example")], %{}, policy())
      end

    assert error.report["findings"] == [
             %{
               "kind" => "literal",
               "offset" => 7,
               "rule_id" => "github-token",
               "subject" => "app.beam"
             }
           ]

    refute inspect(error.report) =~ "ghp_example"
    refute Exception.message(error) =~ "ghp_example"
  end

  test "rejects nested secret config keys without retaining values" do
    error =
      assert_raise SecretAuditError, fn ->
        SecretAudit.analyze!([], %{"auth" => %{"api_token" => "do-not-retain"}}, policy())
      end

    assert hd(error.report["findings"])["subject"] == "auth.api_token"
    refute inspect(error.report) =~ "do-not-retain"
  end

  test "reports all occurrences and rejects explicit scaling bounds" do
    report = SecretAudit.analyze([input("asset", "ghp_one ghp_two")], %{}, policy())
    assert Enum.map(report["findings"], & &1["offset"]) == [0, 8]

    assert_raise ArgumentError, ~r/finding count/, fn ->
      SecretAudit.analyze!([input("asset", "ghp_one ghp_two")], %{}, policy(max_findings: 1))
    end

    assert_raise ArgumentError, ~r/per-input/, fn ->
      SecretAudit.analyze!([input("large", "12345")], %{}, policy(max_input_bytes: 4))
    end
  end

  test "rejects duplicate inputs and policy declarations" do
    assert_raise ArgumentError, ~r/duplicate.*label/, fn ->
      SecretAudit.analyze!([input("same", "a"), input("same", "b")], %{}, policy())
    end

    assert_raise ArgumentError, ~r/duplicate secret literal signature/, fn ->
      policy(rules: [rule("one", "ghp_"), rule("two", "ghp_")])
    end

    assert_raise ArgumentError, ~r/unknown fields/, fn ->
      raw_policy() |> Map.put("extra", true) |> SecretPolicy.new!()
    end
  end

  defp input(label, bytes), do: %{"label" => label, "bytes" => bytes}
  defp policy(options \\ []), do: raw_policy(options) |> SecretPolicy.new!()

  defp rule(id, literal),
    do: %{"id" => id, "literal" => literal, "reason" => "credential signature"}

  defp raw_policy(options \\ []) do
    rows = %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.secret-policy/1",
      "key_fragments" => ["password", "secret", "token"],
      "literal_rules" => Keyword.get(options, :rules, [rule("github-token", "ghp_")]),
      "limits" => %{
        "max_inputs" => 10,
        "max_input_bytes" => Keyword.get(options, :max_input_bytes, 100),
        "max_total_bytes" => 200,
        "max_findings" => Keyword.get(options, :max_findings, 10)
      }
    }

    if Keyword.get(options, :reverse, false),
      do: %{
        rows
        | "key_fragments" => Enum.reverse(rows["key_fragments"]),
          "literal_rules" => Enum.reverse(rows["literal_rules"])
      },
      else: rows
  end
end
