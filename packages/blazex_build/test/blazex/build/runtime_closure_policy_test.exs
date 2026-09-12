defmodule BlazeX.Build.RuntimeClosurePolicyTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.RuntimeClosurePolicy

  test "normalizes unordered declarations without creating policy-dependent atoms" do
    _ = RuntimeClosurePolicy.new!(policy())
    before = :erlang.system_info(:atom_count)
    first = RuntimeClosurePolicy.new!(policy())

    reordered =
      policy()
      |> Map.update!("keep_modules", &Enum.reverse/1)
      |> Map.update!("keep_functions", &Enum.reverse/1)
      |> Map.update!("drop_modules", &Enum.reverse/1)

    second = RuntimeClosurePolicy.new!(reordered)

    assert first.sha256 == second.sha256
    assert first.keep_modules == Enum.sort(first.keep_modules)
    assert :erlang.system_info(:atom_count) == before
  end

  test "rejects unknown fields, duplicates, invalid bounds, and contradictory roots" do
    assert_raise ArgumentError, ~r/missing or unknown/, fn ->
      policy() |> Map.put("surprise", true) |> RuntimeClosurePolicy.new!()
    end

    assert_raise ArgumentError, ~r/duplicate keep modules/, fn ->
      policy()
      |> Map.put("keep_modules", ["Elixir.Example.Root", "Elixir.Example.Root"])
      |> RuntimeClosurePolicy.new!()
    end

    assert_raise ArgumentError, ~r/limits/, fn ->
      policy()
      |> put_in(["limits", "max_outputs"], 101)
      |> RuntimeClosurePolicy.new!()
    end

    assert_raise ArgumentError, ~r/retained root/, fn ->
      policy()
      |> Map.put("drop_modules", ["Elixir.Example.Root"])
      |> RuntimeClosurePolicy.new!()
    end
  end

  def policy do
    %{
      "schema_version" => "1.0.0",
      "policy_id" => "bh06/runtime-closure-test",
      "tool" => %{
        "id" => "fixture-reducer",
        "version" => "1.0.0",
        "lock_sha256" => String.duplicate("a", 64)
      },
      "expected_input" => %{"modules" => 2, "set_sha256" => String.duplicate("b", 64)},
      "keep_modules" => ["Elixir.Example.Root"],
      "keep_functions" => [
        %{"module" => "Elixir.Example.Root", "function" => "start", "arity" => 0},
        %{"module" => "Elixir.Example.Other", "function" => "run", "arity" => 1}
      ],
      "leave_modules" => ["application_controller"],
      "ignore_modules" => ["application_controller", "prim_eval"],
      "drop_modules" => ["Elixir.Example.Unused", "Elixir.Example.UnusedTwo"],
      "limits" => %{
        "max_inputs" => 100,
        "max_name_length" => 128,
        "max_outputs" => 100,
        "max_removed_functions" => 1_000
      }
    }
  end
end
