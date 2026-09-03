defmodule BlazeX.BH01.RuntimeSmoke.Worker do
  @moduledoc false

  def child_spec(owner) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [owner]},
      restart: :permanent,
      shutdown: 100,
      type: :worker
    }
  end

  def start_link(owner) do
    pid = spawn_link(__MODULE__, :init, [owner])
    {:ok, pid}
  end

  def init(owner) do
    send(owner, {:worker_started, self()})
    loop(owner)
  end

  def loop(owner) do
    receive do
      {:echo, caller, request_id, payload} ->
        send(caller, {:echo_reply, self(), request_id, payload})
        loop(owner)

      :controlled_crash ->
        send(owner, {:worker_crashing, self()})
        exit(:controlled_crash)

      :stop ->
        :ok
    end
  end
end
