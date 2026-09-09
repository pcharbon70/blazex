defmodule BlazeX.SchemaTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{Schema, Props}
  @host %{kind: :host, root: "root", owner: "remote"}
  @local %{kind: :local, root: "root", owner: "root"}

  test "all scalar and structural forms normalize" do
    for {type, value, expected} <- [
          {:boolean, true, true},
          {:integer, 5, 5},
          {:float, 1.5, 1.5},
          {:string, "hello", "hello"},
          {:opaque_id, "id", "id"},
          {{:integer, 0, 8}, 8, 8},
          {{:string, 2}, "ok", "ok"},
          {{:enum, ["a", "b"]}, "b", "b"},
          {{:nullable, :integer}, nil, nil},
          {{:tuple, [:integer, :string]}, [1, "a"], {1, "a"}},
          {{:list, :integer, 2}, [1, 2], [1, 2]},
          {{:map, :boolean, 2}, %{"yes" => true}, %{"yes" => true}},
          {{:record, [{"age", :integer}]}, %{"age" => 4}, %{"age" => 4}},
          {{:custom, "age", 1, {:integer, 0, 99}}, 9, 9},
          {{:semantic, 1}, %{"kind" => "text", "value" => "hello"},
           %{"kind" => "text", "value" => "hello"}}
        ] do
      assert Schema.valid?(type)
      assert Schema.normalize(type, value, @host) == {:ok, expected}
    end

    assert Schema.normalize({:tuple, [:integer]}, {1}, @local) == {:ok, {1}}
  end

  test "declaration order, defaults, deprecations and host codec" do
    props = [
      {"z", [type: :integer, default: 2, doc: "z", deprecated: "use other"]},
      {"pair", [type: {:tuple, [:string, :integer]}, default: ["a", 1]]},
      {"a", [type: :string, required: true]}
    ]

    assert {:ok, fields} = Props.declare(props)
    assert Enum.map(fields, & &1.name) == ["z", "pair", "a"]
    assert hd(fields).deprecated == "use other"

    assert Props.normalize(props, %{"a" => "ok"}, @host) ==
             {:ok, %{"z" => 2, "pair" => {"a", 1}, "a" => "ok"}}

    assert Props.encode(props, %{"a" => "ok", "pair" => {"a", 1}}, @host) ==
             {:ok, %{"z" => 2, "pair" => ["a", 1], "a" => "ok"}}

    assert Props.normalize(props, %{"a" => "ok"}, @local) ==
             Props.normalize(props, %{"a" => "ok"}, @host)

    assert {:error, %{code: :required, path: ["a"]}} = Props.normalize(props, %{}, @host)

    assert {:error, %{code: :unknown_prop, path: []}} =
             Props.normalize(props, %{"SECRET" => 1}, @host)
  end

  test "contradictory and executable declarations reject" do
    for declaration <- [
          [{"x", [type: :integer, required: true, default: 1]}],
          [{"x", [type: :integer, default: "bad"]}],
          [{"x", [type: :integer]}, {"x", [type: :integer]}],
          [{"host", [type: :string]}],
          [{"x", [type: :pid]}],
          [{"x", [type: :integer, validator: fn x -> x end]}],
          [{"x", [type: {:callable, 1}]}],
          [{"x", [type: {:custom, "name", 0, :string}]}],
          [{"x", [type: {:callable, 1}, boundary: :local, default: &Kernel.abs/1]}]
        ] do
      assert {:error, _} = Props.declare(declaration)
    end
  end

  test "opaque terms, nested secrets and bounds fail with redacted paths" do
    for value <- [
          self(),
          make_ref(),
          fn -> :ok end,
          %RuntimeError{message: "SECRET"},
          [1 | 2],
          9_007_199_254_740_992,
          "SECRET"
        ] do
      assert {:error, %{path: ["record", "age"]} = diagnostic} =
               Props.normalize(
                 [{"record", [type: {:record, [{"age", :integer}]}]}],
                 %{"record" => %{"age" => value}},
                 @host
               )

      refute inspect(diagnostic) =~ "SECRET"
    end

    assert {:error, %{path: ["data"]}} =
             Props.normalize(
               [{"data", [type: {:map, :string, 2}]}],
               %{"data" => %{"secret" => "SECRET"}},
               @host
             )

    for {type, value} <- [
          {{:string, 1}, "xx"},
          {{:list, :integer, 1}, [1, 2]},
          {{:record, []}, %{"x" => 1}},
          {{:enum, [1]}, 1.0}
        ] do
      assert {:error, _} = Schema.normalize(type, value, @host)
    end

    too_deep = Enum.reduce(1..10, :string, fn _, type -> {:nullable, type} end)
    refute Schema.valid?(too_deep)
  end

  test "local callables are uncaptured, same-root and never invoked" do
    schema = [{"f", [type: {:callable, 1}, boundary: :local]}]
    value = %{"f" => %{owner: "root", callable: &Kernel.abs/1}}
    assert {:ok, ^value} = Props.normalize(schema, value, @local)

    for kind <- [:host, :persistence, :command, :renderer] do
      assert {:error, %{code: :local_only}} =
               Props.normalize(schema, value, %{@host | kind: kind})
    end

    for invalid <- [
          %{owner: "other", callable: &Kernel.abs/1},
          %{owner: "root", callable: fn _ -> raise "must not execute" end}
        ] do
      assert {:error, _} = Props.normalize(schema, %{"f" => invalid}, @local)
    end

    assert {:error, _} = Props.normalize(schema, value, %{@local | owner: "other"})
  end

  test "schema-aware facade metadata is deterministic and versioned" do
    source = """
    defmodule BlazeX.SchemaFixture do
      use BlazeX.Component, role: :pure, schema: [props: [{"title", [type: :string, required: true]}], slots: []]
      def render(_), do: {:rejected, :unsupported}
    end
    """

    assert [{module, _}] = Code.compile_string(source)
    assert module.__blazex_component__().version == Schema.version()
    assert module.__blazex_component__().schema.props |> hd() |> Map.get(:name) == "title"
  end
end
