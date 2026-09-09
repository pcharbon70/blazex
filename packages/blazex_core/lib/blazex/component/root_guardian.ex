defmodule BlazeX.Component.RootGuardian do
  @moduledoc false
  use GenServer
  alias BlazeX.Component.{RootPort, RootProcess}

  def start_link(input), do: GenServer.start_link(__MODULE__, input)

  @impl true
  def init({spec, ports}) do
    with {:ok, spec} <- RootPort.normalize(spec), true <- RootPort.ports?(ports) do
      Process.flag(:trap_exit, true)
      {:ok, worker} = RootProcess.start_link({self(), spec, ports})
      {:ok, %{worker: worker, ports: ports, handle: RootPort.handle(spec), snapshot: nil}}
    else
      _ -> {:stop, :invalid_start}
    end
  end

  @impl true
  def handle_call(:terminal, _from, state) do
    {:reply, {terminal?(state), state.handle.instance}, state}
  end

  def handle_call({handle, operation}, _from, state) do
    cond do
      handle != state.handle ->
        {:reply, {:error, :stale}, state}

      operation == :snapshot and terminal?(state) ->
        {:reply, {:ok, state.snapshot}, state}

      match?({:stop, _}, operation) and terminal?(state) ->
        {:reply, :ok, state}

      terminal?(state) ->
        {:reply, {:error, :terminal}, state}

      true ->
        try do
          {reply, snapshot} = GenServer.call(state.worker, operation, 60_000)
          {:reply, reply, %{state | snapshot: snapshot}}
        catch
          :exit, _ ->
            next = crashed(state)
            {:reply, {:error, :crashed}, next}
        end
    end
  end

  @impl true
  def handle_info({:root_snapshot, worker, snapshot}, %{worker: worker} = state) do
    if terminal?(state), do: {:noreply, state}, else: {:noreply, %{state | snapshot: snapshot}}
  end

  def handle_info({:EXIT, worker, _private_reason}, %{worker: worker} = state) do
    {:noreply, if(terminal?(state), do: %{state | worker: nil}, else: crashed(state))}
  end

  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def terminate(_, state) do
    if is_pid(state.worker), do: :erlang.exit(state.worker, :shutdown)
    :ok
  end

  @impl true
  def format_status(status),
    do:
      Map.new(status, fn {key, _} ->
        {key, if(key == :log, do: [], else: :redacted_root_guardian)}
      end)

  defp terminal?(%{snapshot: %{status: status}}), do: status in [:disposed, :failed]
  defp terminal?(_), do: false

  defp crashed(state) do
    snapshot =
      state.snapshot ||
        %{
          contract: RootPort.version(),
          handle: state.handle,
          status: :starting,
          accepted: nil,
          pending: nil,
          attempt: 0,
          error: nil
        }

    snapshot = %{snapshot | status: :failed, pending: nil, error: :crashed}
    RootPort.call(state.ports.host, :notify, [Map.put(snapshot, :event, :crashed)])
    if is_pid(state.worker), do: :erlang.exit(state.worker, :kill)
    %{state | snapshot: snapshot, worker: nil}
  end
end
