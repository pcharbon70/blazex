defmodule BlazeX.Build.ClientSafetyTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{ClientSafety, ClientSafetyError, ClientSafetyPolicy}

  @root %{
    "module" => "Elixir.App.Root",
    "application" => "app",
    "imports" => [%{"module" => "erlang", "function" => "+", "arity" => 2}]
  }
  @reachability %{
    "modules" => [%{"module" => "Elixir.App.Root"}],
    "external_references" => [
      %{"from" => "Elixir.App.Root", "module" => "erlang", "function" => "+", "arity" => 2}
    ]
  }

  test "classifies a fully explained candidate deterministically" do
    policy = policy()
    one = ClientSafety.analyze!(@reachability, [@root], policy)
    two = ClientSafety.analyze!(@reachability, [@root], policy(reversed: true))
    assert one == two
    assert one["policy_sha256"] == policy.sha256

    assert one["modules"] == [
             %{
               "module" => "Elixir.App.Root",
               "application" => "app",
               "classification" => "client-safe",
               "rule" => %{"kind" => "application", "id" => "app"},
               "reason" => "portable application"
             }
           ]

    assert one["summary"] == %{
             "client_safe_modules" => 1,
             "external_modules" => 1,
             "forbidden_primitives_checked" => 4,
             "reachable_modules" => 1,
             "runtime_safe_externals" => 1,
             "violations" => 0
           }
  end

  test "exact module override takes precedence over application policy" do
    policy =
      policy(
        applications: [rule("app", "server-only", "server application")],
        module_overrides: [rule("Elixir.App.Root", "client-safe", "reviewed exception")]
      )

    report = ClientSafety.analyze!(@reachability, [@root], policy)
    assert hd(report["modules"])["rule"] == %{"kind" => "module", "id" => "Elixir.App.Root"}
  end

  test "rejects server-only and native reachable modules" do
    for classification <- ["server-only", "native"] do
      error =
        assert_raise ClientSafetyError, fn ->
          ClientSafety.analyze!(
            @reachability,
            [@root],
            policy(applications: [rule("app", classification, "unsafe dependency")])
          )
        end

      assert Exception.message(error) =~ "module:Elixir.App.Root:#{classification}"
    end
  end

  test "rejects unknown application ownership and external modules" do
    unknown_app = %{@root | "application" => "unknown"}

    assert_raise ClientSafetyError, ~r/module:Elixir.App.Root:unknown/, fn ->
      ClientSafety.analyze!(@reachability, [unknown_app], policy())
    end

    reachability =
      put_in(@reachability["external_references"], [
        %{"from" => "Elixir.App.Root", "module" => "os", "function" => "cmd", "arity" => 1}
      ])

    assert_raise ClientSafetyError, ~r/external:os:unknown/, fn ->
      ClientSafety.analyze!(reachability, [@root], policy(external_modules: []))
    end
  end

  test "rejects external server policy" do
    assert_raise ClientSafetyError, ~r/external:erlang:server-only/, fn ->
      ClientSafety.analyze!(
        @reachability,
        [@root],
        policy(external_modules: [rule("erlang", "server-only", "server runtime")])
      )
    end
  end

  test "rejects NIF and port primitives despite a client-safe application" do
    for {function, arity} <- [{"load_nif", 2}, {"open_port", 2}, {"port_command", 3}] do
      fact =
        put_in(@root["imports"], [
          %{"module" => "erlang", "function" => function, "arity" => arity}
        ])

      reachability =
        put_in(@reachability["external_references"], [
          %{
            "from" => "Elixir.App.Root",
            "module" => "erlang",
            "function" => function,
            "arity" => arity
          }
        ])

      assert_raise ClientSafetyError, ~r/forbidden-import:Elixir.App.Root:native/, fn ->
        ClientSafety.analyze!(reachability, [fact], policy())
      end
    end
  end

  test "rejects unused declarations" do
    assert_raise ClientSafetyError, ~r/unused-module-override:Elixir.App.Other:policy/, fn ->
      ClientSafety.analyze!(
        @reachability,
        [@root],
        policy(module_overrides: [rule("Elixir.App.Other", "client-safe", "unused")])
      )
    end
  end

  test "rejects duplicate, contradictory, malformed, and unbounded policy records" do
    assert_raise ArgumentError, ~r/duplicate application rule/, fn ->
      raw_policy(
        applications: [
          rule("app", "client-safe", "one"),
          rule("app", "native", "two")
        ]
      )
      |> ClientSafetyPolicy.new!()
    end

    assert_raise ArgumentError, ~r/forbidden import rule is invalid/, fn ->
      raw_policy(forbidden_imports: [forbidden("load_nif", [2, 2])])
      |> ClientSafetyPolicy.new!()
    end

    assert_raise ArgumentError, ~r/application rule is invalid/, fn ->
      raw_policy(applications: [rule("Bad App", "client-safe", "bad")])
      |> ClientSafetyPolicy.new!()
    end
  end

  defp policy(options \\ []), do: raw_policy(options) |> ClientSafetyPolicy.new!()

  defp raw_policy(options) do
    applications =
      Keyword.get(options, :applications, [rule("app", "client-safe", "portable application")])

    overrides = Keyword.get(options, :module_overrides, [])

    external =
      Keyword.get(options, :external_modules, [
        rule("erlang", "runtime-safe", "runtime primitive")
      ])

    forbidden =
      Keyword.get(options, :forbidden_imports, [
        forbidden("load_nif", [2]),
        forbidden("open_port", [2]),
        forbidden("port_command", [2, 3])
      ])

    rows = %{
      "schema_version" => "1.0.0",
      "policy_id" => "test.client-safety/1",
      "applications" => applications,
      "module_overrides" => overrides,
      "external_modules" => external,
      "forbidden_imports" => forbidden
    }

    if Keyword.get(options, :reversed, false) do
      Map.new(rows, fn {key, value} ->
        {key, if(is_list(value), do: Enum.reverse(value), else: value)}
      end)
    else
      rows
    end
  end

  defp rule(id, classification, reason),
    do: %{"id" => id, "classification" => classification, "reason" => reason}

  defp forbidden(function, arities),
    do: %{
      "module" => "erlang",
      "function" => function,
      "arities" => arities,
      "classification" => "native",
      "reason" => "native primitive"
    }
end
