defmodule BlazeX.Renderer.DOM.ProtocolTest do
  use ExUnit.Case, async: true
  alias BlazeX.Renderer.DOM.Protocol
  alias BlazeX.Renderer.DOM.Protocol.Codec

  @fixtures Path.expand("../../../integration/bh-04/protocol-fixtures-v0.1.0.txt", __DIR__)

  for line <- File.read!(@fixtures) |> String.split("\n", trim: true) do
    [name, expected, context, record] = String.split(line, "|")

    test "shared protocol fixture: #{name}" do
      {:ok, context} = unquote(context) |> Base.decode64!() |> Codec.decode()

      result =
        with {:ok, record} <- unquote(record) |> Base.decode64!() |> Codec.decode(),
             {:ok, value} <- Protocol.new(record, context),
             do: {:ok, Protocol.to_wire(value)}

      case result do
        {:ok, value} ->
          assert unquote(expected) == "ok"
          assert {:ok, ^value} = value |> Codec.encode!() |> Codec.decode()

        {:error, code} ->
          assert code == unquote(expected)
      end
    end
  end

  test "compatibility and immutable operation constructors" do
    assert {:ok, _} =
             Protocol.compatibility("blazex.dom-transaction/1", "1.0.0", ["atomic", "ordered"])

    assert {:error, "incompatible"} = Protocol.compatibility("unknown", "1.0.0", [])
    assert Protocol.limits().queue == 64
    assert {:error, "malformed"} = Protocol.operation(%{})
  end

  test "canonical ordering and closed local values" do
    assert Codec.encode!(%{"a" => 1, "b" => "🌍"}) ==
             Codec.encode!(Map.new([{"b", "🌍"}, {"a", 1}]))

    for value <- [-1, 1.5, :atom, self(), %{a: 1}, <<255>>] do
      assert {:error, "malformed"} = Codec.encode(value)
    end
  end
end
