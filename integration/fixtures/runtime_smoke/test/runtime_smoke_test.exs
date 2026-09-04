defmodule BlazeX.BH01.RuntimeSmokeTest do
  use ExUnit.Case, async: false

  test "disposable fixture completes its bounded BEAM lifecycle" do
    assert :ok = BlazeX.BH01.RuntimeSmoke.start()
  end

  test "fixture protocol rejects stale, duplicate, forbidden, and post-disposal traffic" do
    alias BlazeX.BH01.RuntimeSmoke.Protocol

    request = %{
      "version" => 1,
      "request_id" => 1,
      "generation" => 1,
      "tag" => "echo",
      "payload" => %{"value" => 7}
    }

    state = Protocol.new_state()
    assert {:ok, %{"request_id" => 1}, accepted} = Protocol.accept(request, state)
    assert {:ok, settled} = Protocol.settle_reply(1, 1, accepted)
    assert {:error, :duplicate_request, ^accepted} = Protocol.accept(request, accepted)
    assert {:error, :duplicate_reply, ^settled} = Protocol.settle_reply(1, 1, settled)

    assert {:error, :stale_generation, ^accepted} =
             Protocol.accept(%{request | "request_id" => 2, "generation" => 9}, accepted)

    assert {:error, :unknown_tag, ^accepted} =
             Protocol.accept(%{request | "request_id" => 3, "tag" => "eval"}, accepted)

    assert {:error, :forbidden_or_non_string_key, ^accepted} =
             Protocol.accept(
               %{request | "request_id" => 4, "payload" => %{"code" => "alert(1)"}},
               accepted
             )

    disposed = Protocol.dispose(settled)

    assert {:error, :disposed, ^disposed} =
             Protocol.accept(%{request | "request_id" => 5}, disposed)

    assert {:error, :disposed, ^disposed} = Protocol.settle_reply(1, 1, disposed)
    assert {:error, :host, :denied} = Protocol.classify_failure({:host_error, :denied})
    assert {:error, :runtime, :crashed} = Protocol.classify_failure({:runtime_error, :crashed})
  end
end
