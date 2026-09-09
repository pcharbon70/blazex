{:ok, _, []} =
  Kernel.ParallelCompiler.compile(Path.wildcard("packages/blazex_core/lib/**/*.ex"),
    warnings_as_errors: true
  )

ExUnit.start()

unless ExUnit.CaptureIO.capture_io(:stderr, fn ->
         Code.compile_file("integration/bh-05/schema-fixtures.exs")
       end) == "",
       do: raise("valid schema fixtures emitted compiler warnings")

defmodule BlazeX.BH05.SchemaCheck do
  use ExUnit.Case
  alias BlazeX.Component.{Invocation, Props, Schema}

  test "public facade fixture metadata and normalization are deterministic without callbacks" do
    metadata = BlazeX.BH05.SchemaCard.__blazex_component__()
    assert metadata.version == Schema.version()
    assert Enum.map(metadata.schema.props, & &1.name) == ["title", "count", "pair"]
    assert hd(metadata.schema.slots).name == "default"
    assert {:ok, invocation} = BlazeX.BH05.SchemaData.normalize()
    assert invocation.props == %{"title" => "Example", "count" => 0, "pair" => {"a", 1}}
    assert BlazeX.BH05.SchemaData.normalize() == {:ok, invocation}

    digest =
      :crypto.hash(:sha256, :erlang.term_to_binary(invocation, [:deterministic]))
      |> Base.encode16(case: :lower)

    IO.puts("NORMALIZED_SCHEMA_FIXTURE_SHA256 " <> digest)
    IO.puts("SCHEMA_METADATA " <> inspect(metadata, limit: :infinity))

    assert {:error, diagnostic, ^invocation} =
             Invocation.update(
               invocation,
               metadata.schema.declarations,
               %{"title" => self()},
               %{},
               %{kind: :host, root: "example", owner: "adapter"}
             )

    assert diagnostic.code == :type
  end

  test "compile rejection of unstable defaults validators schema versions and ordering" do
    for {schema, index} <-
          Enum.with_index([
            "[props: [{\"x\", [type: :string, default: self()]}], slots: []]",
            "[props: [{\"x\", [type: :string, validator: fn x -> x end]}], slots: []]",
            "[props: [{\"x\", [type: {:custom, \"x\", 0, :string}]}], slots: []]",
            "[slots: [], props: []]",
            "[props: [], slots: [{\"x\", [required: true, min: 0]}]]",
            "[props: [], slots: [{\"x\", [boundary: :host, context: {:callable, 1}]}]]",
            "[props: [{\"x\", [type: :string, type: :integer]}], slots: []]"
          ]) do
      error =
        assert_raise CompileError, fn ->
          Code.compile_string(
            "defmodule BlazeX.BH05.BadSchema#{index} do use BlazeX.Component, role: :pure, schema: #{schema}; def render(_), do: :ok end"
          )
        end

      assert error.description in [
               "BH-05 authoring: invalid_schema",
               "BH-05 authoring: invalid_declaration"
             ]
    end

    assert_raise CompileError, "BH-05 authoring: invalid_declaration", fn ->
      Code.compile_string(
        "defmodule BlazeX.BH05.ExecutableDefault do use BlazeX.Component, role: :pure, schema: [props: [{\"x\", [type: :integer, default: send(self(), :schema_executed)]}], slots: []]; def render(_), do: :ok end"
      )
    end

    refute_received :schema_executed
  end

  test "wire codec rejects framework, secret, opaque, improper and excessive values" do
    boundary = %{kind: :host, root: "r", owner: "adapter"}

    for value <- [
          %RuntimeError{message: "PRIVATE"},
          %{"secret" => "PRIVATE"},
          self(),
          make_ref(),
          fn -> :ok end,
          [1 | 2],
          Enum.to_list(1..257)
        ] do
      assert {:error, diagnostic} =
               Props.encode(
                 [{"value", [type: {:list, :integer, 256}]}],
                 %{"value" => value},
                 boundary
               )

      refute inspect(diagnostic) =~ "PRIVATE"
    end

    deep = Enum.reduce(1..100, 1, fn _, acc -> [acc] end)
    assert {:error, _} = Props.encode([{"value", [type: :integer]}], %{"value" => deep}, boundary)
  end
end
