defmodule BlazeX.Component.RecoveryPort do
  @moduledoc "Runtime-owned bounded port invocation for opt-in recovery roots."
  alias BlazeX.Component.RootPort

  def call(port, callback, arguments, timeout) when is_integer(timeout) and timeout > 0 do
    caller = self()
    token = make_ref()

    {pid, monitor} =
      :erlang.spawn_opt(
        fn ->
          result = RootPort.call(port, callback, arguments)
          send(caller, {token, result})
        end,
        [:link, :monitor]
      )

    receive do
      {^token, result} ->
        Process.unlink(pid)

        receive do
          {:DOWN, ^monitor, :process, ^pid, _} -> :ok
        end

        flush_exit(pid)
        result

      {:DOWN, ^monitor, :process, ^pid, _} ->
        flush_exit(pid)
        {:error, :port_failed}
    after
      timeout ->
        Process.unlink(pid)
        Process.exit(pid, :kill)

        receive do
          {:DOWN, ^monitor, :process, ^pid, _} -> :ok
        end

        flush_exit(pid)

        receive do
          {^token, _} -> :ok
        after
          0 -> :ok
        end

        {:error, :timed_out}
    end
  end

  def call(_, _, _, _), do: {:error, :timed_out}

  defp flush_exit(pid) do
    receive do
      {:EXIT, ^pid, _} -> :ok
    after
      0 -> :ok
    end
  end

  for {name, arity} <- [
        submit: 2,
        submit: 1,
        select: 1,
        cancel: 1,
        notify: 1,
        dispose: 1,
        force_cleanup: 1,
        release: 1
      ] do
    args = Macro.generate_arguments(arity, __MODULE__)

    def unquote(name)({port, timeout}, unquote_splicing(args)),
      do: call(port, unquote(name), [unquote_splicing(args)], timeout)
  end
end
