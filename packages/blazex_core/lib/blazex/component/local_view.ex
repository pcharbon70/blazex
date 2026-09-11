defmodule BlazeX.Component.LocalView do
  @moduledoc """
  Runtime-facing supervised root API. Supervisor references belong to runtime
  composition; returned component handles contain root/instance/owner only.
  Terminal roots are retained for inspection until `release_terminal/2` or an
  explicit new instance removes the private guardian.
  """
  alias BlazeX.Component.{ActionRuntime, RootGuardian, RootPort, RootSchedule, SchedulingPort}

  def start(supervisor, spec, ports, policy \\ nil, actions \\ nil, recovery \\ nil) do
    with {:ok, spec} <- RootPort.normalize(spec),
         true <- RootPort.ports?(ports),
         {:ok, _} <- RootSchedule.new(policy),
         :ok <- ActionRuntime.validate(actions),
         true <- recovery == nil or BlazeX.Component.RecoveryPolicy.validate(recovery),
         true <- policy == nil or SchedulingPort.supported?(ports.evaluator),
         true <-
           actions == nil or
             (policy != nil and function_exported?(elem(ports.evaluator, 0), :admit_action, 3)),
         :ok <- vacant(supervisor, spec),
         {:ok, _private_pid} <-
           Supervisor.start_child(
             supervisor,
             if(recovery == nil,
               do: child_spec({spec, ports, policy, actions}),
               else: child_spec({spec, ports, policy, actions, recovery})
             )
           ) do
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

  def child_spec({spec, ports, policy}), do: child_spec({spec, ports, policy, nil})

  def child_spec({spec, ports, policy, actions}) do
    %{
      id: {:blazex_root, spec.root},
      start: {RootGuardian, :start_link, [{spec, ports, policy, actions}]},
      restart: :temporary,
      shutdown: 5000,
      type: :worker
    }
  end

  def child_spec({spec, ports, policy, actions, recovery}) do
    %{
      child_spec({spec, ports, policy, actions})
      | start:
          {BlazeX.Component.RecoveryGuardian, :start_link,
           [{spec, ports, policy, actions, recovery}]}
    }
  end

  def retry(supervisor, handle, request), do: request(supervisor, handle, {:retry, request})

  def inspect_root(supervisor, handle), do: request(supervisor, handle, :snapshot)

  def enqueue(supervisor, handle, envelope), do: request(supervisor, handle, {:enqueue, envelope})

  def runtime_loss(supervisor, handle), do: request(supervisor, handle, :runtime_loss)

  def action_result(supervisor, handle, result),
    do: request(supervisor, handle, {:action_result, result})

  def update(supervisor, handle, revision, props, slots \\ %{}),
    do: request(supervisor, handle, {:update, revision, props, slots})

  def replace(supervisor, handle, revision, spec),
    do: request(supervisor, handle, {:replace, revision, spec})

  def acknowledge(supervisor, handle, acknowledgement),
    do: request(supervisor, handle, {:ack, acknowledgement})

  def stop(supervisor, handle, reason \\ :shutdown),
    do: request(supervisor, handle, {:stop, reason})

  @doc "Release an inspected terminal guardian; repeated release is a no-op."
  def release_terminal(supervisor, handle) do
    if RootPort.handle?(handle) do
      case locate(supervisor, handle.root) do
        nil ->
          :ok

        pid ->
          with {:ok, _snapshot} <- GenServer.call(pid, {handle, :snapshot}),
               {true, _instance} <- GenServer.call(pid, :terminal),
               :ok <- remove(supervisor, handle.root) do
            :ok
          else
            {false, _instance} -> {:error, :not_terminal}
            {:error, :stale} -> {:error, :stale}
            _ -> {:error, :terminal_release_failed}
          end
      end
    else
      {:error, :invalid_request}
    end
  catch
    :exit, _ -> {:error, :terminal_release_failed}
  end

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
            remove(supervisor, spec.root)

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

  defp remove(supervisor, root) do
    id = {:blazex_root, root}

    with :ok <- Supervisor.terminate_child(supervisor, id) do
      case Supervisor.delete_child(supervisor, id) do
        :ok -> :ok
        {:error, :not_found} -> :ok
        error -> error
      end
    end
  end
end

defmodule BlazeX.Component.LocalView.Supervisor do
  @moduledoc "Runtime-owned one-for-one supervisor; each root child is temporary."
  use Supervisor
  def start_link(options \\ []), do: Supervisor.start_link(__MODULE__, :ok, options)
  @impl true
  def init(:ok), do: Supervisor.init([], strategy: :one_for_one)
end
