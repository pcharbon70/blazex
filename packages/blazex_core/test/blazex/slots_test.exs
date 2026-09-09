defmodule BlazeX.SlotsTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{Invocation, Slots}
  @local %{kind: :local, root: "root", owner: "root"}
  @host %{kind: :host, root: "root", owner: "remote"}
  @slots [
    {"default",
     [
       required: true,
       max: 2,
       key: :required,
       props: [{"label", [type: :string, default: "item"]}],
       context: {:record, [{"count", :integer}]}
     ]},
    {"footer", [key: :optional]}
  ]

  defp entry(key \\ "one"),
    do: %{
      "key" => key,
      "context" => %{"count" => 1},
      "content" => %{"owner" => "root", "caller" => "lexical-parent", "id" => "content"}
    }

  test "default named contextual multiple slots normalize in declaration and entry order" do
    input = %{
      "default" => [entry("b"), entry("a")],
      "footer" => [%{"content" => entry()["content"]}]
    }

    assert {:ok, [{"default", [b, a]}, {"footer", [footer]}]} =
             Slots.normalize(@slots, input, @local)

    assert b.key == "b" and a.key == "a"
    assert b.props == %{"label" => "item"}
    assert b.context == %{"count" => 1}
    assert footer.key == {:ordinal, 0}
    assert footer.context == %{}

    assert Slots.normalize(@slots, input, @local) ==
             Slots.normalize(@slots, Map.new(Enum.reverse(Enum.to_list(input))), @local)
  end

  test "missing excess unknown duplicate cross-root and malformed entries reject" do
    for values <- [
          %{},
          %{"default" => []},
          %{"unknown-secret" => []},
          %{"default" => [entry(), entry()]},
          %{"default" => [entry("a"), entry("b"), entry("c")]},
          %{"default" => [Map.delete(entry(), "key")]},
          %{"default" => [put_in(entry(), ["content", "owner"], "other")]},
          %{"default" => [Map.put(entry(), "props", %{"secret" => "PRIVATE"})]},
          %{"default" => [Map.put(entry(), "context", %{"count" => self()})]},
          %{"default" => [Map.put(entry(), "content", fn -> raise "must never execute" end)]}
        ] do
      assert {:error, diagnostic} = Slots.normalize(@slots, values, @local)
      refute inspect(diagnostic) =~ "PRIVATE"
      refute inspect(diagnostic) =~ "unknown-secret"
    end

    assert {:error, %{code: :local_only}} =
             Slots.normalize(@slots, %{"default" => [entry()]}, @host)
  end

  test "declaration contradictions and host-only context restrictions" do
    for schema <- [
          [{"x", [required: true, min: 0]}],
          [{"x", [min: 2, max: 1]}],
          [{"x", [max: 257]}],
          [{"x", [key: :none]}],
          [{"host", []}],
          [{"x", []}, {"x", []}],
          [{"x", [boundary: :host, context: {:callable, 1}]}],
          [{"x", [boundary: :host, props: [{"f", [type: {:callable, 1}, boundary: :local]}]]}]
        ] do
      assert {:error, _} = Slots.declare(schema)
    end

    host_slots = [{"default", [boundary: :host, key: :optional]}]
    value = %{"default" => [%{"content" => %{"kind" => "text", "value" => "hello"}}]}
    assert {:ok, _} = Slots.normalize(host_slots, value, @host)
    assert {:error, _} = Slots.normalize(host_slots, %{"default" => [entry()]}, @host)
  end

  test "props and slots validate atomically and invalid updates preserve exact prior invocation" do
    schema = [props: [{"title", [type: :string, required: true]}], slots: @slots]

    assert {:ok, before} =
             Invocation.normalize(schema, %{"title" => "old"}, %{"default" => [entry()]}, @local)

    assert {:error, _, ^before} =
             Invocation.update(
               before,
               schema,
               %{"title" => "new"},
               %{"default" => [entry(), entry()]},
               @local
             )

    assert {:error, _, ^before} =
             Invocation.update(
               before,
               schema,
               %{"title" => self()},
               %{"default" => [entry()]},
               @local
             )

    assert {:error, _, ^before} =
             Invocation.update(before, schema, %{"title" => "new"}, %{"default" => [entry()]}, %{
               @local
               | root: "other",
                 owner: "other"
             })

    assert {:ok, after_value} =
             Invocation.update(
               before,
               schema,
               %{"title" => "new"},
               %{"default" => [entry("two")]},
               @local
             )

    assert after_value.props == %{"title" => "new"}
    assert before.props == %{"title" => "old"}
  end
end
