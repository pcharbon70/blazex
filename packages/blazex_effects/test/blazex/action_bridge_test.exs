defmodule BlazeX.ActionBridgeTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.Action
  alias BlazeX.Effects.{ActionBridge, Effect}

  defmodule Provider do
    def submit(pid, packet),
      do:
        (
          send(pid, {:packet, packet})
          :accepted
        )

    def cancel(pid, packet),
      do:
        (
          send(pid, {:canceled, packet})
          :ok
        )

    def release(_, _), do: :released
  end

  defp config,
    do: %{
      grants: [:"ui.storage"],
      bindings: %{"read" => %{primary: "primary", fallback: "fallback"}},
      commands: %{},
      providers: %{"primary" => {Provider, self()}, "fallback" => {Provider, self()}}
    }

  defp descriptor,
    do: %{
      kind: :effect_request,
      id: "read",
      declaration: %{capability: "ui.storage", operation: "get", fallback: :deny}
    }

  test "capability negotiation denies by default and uses only declared provider/fallback bindings" do
    assert {:granted, "primary"} = ActionBridge.select(config(), descriptor())
    assert :denied = ActionBridge.select(%{config() | grants: []}, descriptor())

    assert {:fallback, "fallback"} =
             ActionBridge.select(
               %{config() | grants: []},
               put_in(descriptor(), [:declaration, :fallback], :component)
             )

    assert :denied =
             ActionBridge.select(
               config(),
               put_in(descriptor(), [:declaration, :operation], "unknown")
             )

    assert :denied = ActionBridge.select(%{config() | providers: %{}}, descriptor())
    assert :denied = ActionBridge.select(config(), %{kind: :command, id: "save"})
  end

  test "outward submission binds existing effect contracts without passing configuration to components" do
    owner = %{root: "r", path: [], generation: 1}

    {:ok, action} =
      Action.new(:effect_request, "read_1", 1, owner, %{
        declaration: "read",
        payload: %{"key" => "public"},
        timeout_ms: 1000,
        idempotency_key: "request",
        fallback: :deny
      })

    entry = %{
      action: action,
      correlation: Action.correlation(action, %{root: "r", instance: "i", owner: "runtime"}),
      declaration: descriptor().declaration,
      selection: %{name: "primary"}
    }

    assert :accepted = ActionBridge.submit(config(), entry)
    assert_receive {:packet, packet}
    assert Effect.valid?(packet.effect)
    assert packet.correlation == entry.correlation
    assert packet.effect.payload == %{"key" => "public"}
    assert :ok = ActionBridge.cancel(config(), entry)
    assert_receive {:canceled, ^packet}
  end
end
