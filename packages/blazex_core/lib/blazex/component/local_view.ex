defmodule BlazeX.Component.LocalView do
  @moduledoc """
  Runtime-facing supervised root API. Supervisor references belong to runtime
  composition; returned component handles contain root/instance/owner only.
  Terminal roots are retained for inspection until an explicit new instance.
  """
  alias BlazeX.Component.{RootGuardian, RootPort, RootSchedule, SchedulingPort}

  def start(supervisor, spec, ports, policy \\ nil) do
    with {:ok, spec} <- RootPort.normalize(spec),
         true <- RootPort.ports?(ports),
         {:ok, _} <- RootSchedule.new(policy),
         true <- policy == nil or SchedulingPort.supported?(ports.evaluator),
         :ok <- vacant(supervisor, spec),
         {:ok, _private_pid} <-
           Supervisor.start_child(supervisor, child_spec({spec, ports, policy})) do
      {:ok, RootPort.handle(spec)}
    else
      {:error, code} when code in [:invalid_start, :already_started, :instance_reused] ->
        {:error, code}

      _ ->
        {:error, :invalid_start}
    end
  catch
    :exit, _ -> {:error, :invalid_start}
  end

  @doc "OTP runtime child specification, not a component reference."
  def child_spec({spec, ports}), do: child_spec({spec, ports, nil})

  def child_spec({spec, ports, policy}) do
    %{
      id: {:blazex_root, spec.root},
      start: {RootGuardian, :start_link, [{spec, ports, policy}]},
      restart: :temporary,
      shutdown: 5000,
      type: :worker
    }
  end

  def inspect_root(supervisor, handle), do: request(supervisor, handle, :snapshot)

  def enqueue(supervisor, handle, envelope), do: request(supervisor, handle, {:enqueue, envelope})

  def update(supervisor, handle, revision, props, slots \\ %{}),
    do: request(supervisor, handle, {:update, revision, props, slots})

  def replace(supervisor, handle, revision, spec),
    do: request(supervisor, handle, {:replace, revision, spec})

  def acknowledge(supervisor, handle, acknowledgement),
    do: request(supervisor, handle, {:ack, acknowledgement})

  def stop(supervisor, handle, reason \\ :shutdown),
    do: request(supervisor, handle, {:stop, reason})

  defp request(supervisor, handle, operation) do
    if RootPort.handle?(handle) do
      case locate(supervisor, handle.root) do
        nil -> {:error, :terminal}
        pid -> GenServer.call(pid, {handle, operation}, 65_000)
      end
    else
      {:error, :invalid_request}
    end
  catch
    :exit, _ -> {:error, :terminal}
  end

  defp vacant(supervisor, spec) do
    case locate(supervisor, spec.root) do
      nil ->
        :ok

      pid ->
        case GenServer.call(pid, :terminal) do
          {true, instance} when instance != spec.instance ->
            :ok = Supervisor.terminate_child(supervisor, {:blazex_root, spec.root})

            case Supervisor.delete_child(supervisor, {:blazex_root, spec.root}) do
              :ok -> :ok
              {:error, :not_found} -> :ok
              error -> error
            end

          {true, _} ->
            {:error, :instance_reused}

          _ ->
            {:error, :already_started}
        end
    end
  end

  defp locate(supervisor, root) do
    Enum.find_value(Supervisor.which_children(supervisor), fn
      {{:blazex_root, ^root}, pid, _, _} when is_pid(pid) -> pid
      _ -> nil
    end)
  end
end

defmodule BlazeX.Component.LocalView.Supervisor do
  @moduledoc "Runtime-owned one-for-one supervisor; each root child is temporary."
  use Supervisor
  def start_link(options \\ []), do: Supervisor.start_link(__MODULE__, :ok, options)
  @impl true
  def init(:ok), do: Supervisor.init([], strategy: :one_for_one)
end
