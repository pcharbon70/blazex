defmodule BlazeX.Build.RuntimeClosureTest do
  use ExUnit.Case, async: true

  alias BlazeX.Build.{RuntimeClosure, RuntimeClosurePolicy}

  test "reports a deterministic, path-free reduction with retained roots" do
    root = beam("Elixir.BH06AuditRoot")
    unused = beam("Elixir.BH06AuditUnused")
    inputs = inputs(root, unused)
    policy = policy(inputs)

    first_dir = temporary("first")
    second_dir = temporary("second")
    first = write_beam(first_dir, root)
    second = write_beam(second_dir, root)

    removed = [%{"module" => root.module, "function" => "unused", "arity" => 1}]
    report = RuntimeClosure.audit!(inputs, [first], removed, policy)
    repeated = RuntimeClosure.audit!(Enum.reverse(inputs), [second], removed, policy)

    assert report == repeated
    assert report["removed_modules"] == [unused.module]
    assert report["summary"]["before_modules"] == 2
    assert report["summary"]["after_modules"] == 1
    assert report["summary"]["removed_functions"] == 1
    refute inspect(report) =~ first_dir
    refute inspect(report) =~ second_dir
  end

  test "rejects input drift, output additions, missing roots, and malformed function evidence" do
    root = beam("Elixir.BH06AuditRootFailure")
    unused = beam("Elixir.BH06AuditUnusedFailure")
    addition = beam("Elixir.BH06AuditAdditionFailure")
    inputs = inputs(root, unused)
    policy = policy(inputs)
    dir = temporary("failure")
    root_path = write_beam(dir, root)

    assert_raise ArgumentError, ~r/input set/, fn ->
      drifted =
        List.update_at(inputs, 1, &Map.update!(&1, "bytes", fn bytes -> bytes <> "drift" end))

      RuntimeClosure.audit!(drifted, [root_path], [], policy)
    end

    assert_raise ArgumentError, ~r/outside the authorized input/, fn ->
      RuntimeClosure.audit!(inputs, [root_path, write_beam(dir, addition)], [], policy)
    end

    assert_raise ArgumentError, ~r/retained roots/, fn ->
      RuntimeClosure.audit!(inputs, [write_beam(dir, unused)], [], policy)
    end

    assert_raise ArgumentError, ~r/removed function row/, fn ->
      RuntimeClosure.audit!(
        inputs,
        [root_path],
        [
          %{"module" => unused.module, "function" => "gone", "arity" => 0}
        ],
        policy
      )
    end
  end

  defp inputs(root, unused) do
    [
      %{"module" => root.module, "bytes" => root.bytes <> String.duplicate("r", 64)},
      %{"module" => unused.module, "bytes" => unused.bytes <> String.duplicate("u", 64)}
    ]
  end

  defp policy(inputs) do
    RuntimeClosurePolicy.new!(%{
      "schema_version" => "1.0.0",
      "policy_id" => "bh06/runtime-closure-audit-test",
      "tool" => %{
        "id" => "fixture-reducer",
        "version" => "1.0.0",
        "lock_sha256" => String.duplicate("a", 64)
      },
      "expected_input" => %{
        "modules" => 2,
        "set_sha256" => RuntimeClosure.input_set_sha256(inputs)
      },
      "keep_modules" => [hd(inputs)["module"]],
      "keep_functions" => [
        %{"module" => hd(inputs)["module"], "function" => "start", "arity" => 0}
      ],
      "leave_modules" => [hd(inputs)["module"]],
      "ignore_modules" => [],
      "drop_modules" => [],
      "limits" => %{
        "max_inputs" => 10,
        "max_name_length" => 128,
        "max_outputs" => 10,
        "max_removed_functions" => 100
      }
    })
  end

  defp beam(module) do
    source = "defmodule #{module} do\n  def start, do: :ok\n  def unused(value), do: value\nend"
    [{atom, bytes}] = Code.compile_string(source)
    %{module: Atom.to_string(atom), bytes: bytes}
  end

  defp temporary(label) do
    path =
      Path.join(
        System.tmp_dir!(),
        "blazex-runtime-closure-#{label}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    on_exit(fn -> File.rm_rf!(path) end)
    path
  end

  defp write_beam(directory, beam) do
    path = Path.join(directory, "#{beam.module}.beam")
    File.write!(path, beam.bytes)
    path
  end
end
