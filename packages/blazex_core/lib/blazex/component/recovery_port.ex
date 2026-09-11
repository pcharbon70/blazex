defmodule BlazeX.Component.RecoveryPort do
  @moduledoc "Runtime-owned bounded port invocation for opt-in recovery roots."
  alias BlazeX.Component.RootPort

  @page_size 64
  @maximum_page_size 128

  def page_size, do: @page_size
  def maximum_page_size, do: @maximum_page_size

  def open_session do
    owner = self()
    token = make_ref()

    {pid, monitor} =
      :erlang.spawn_opt(
        fn -> session_loop(owner, token, Process.monitor(owner), %{}) end,
        [:link, :monitor]
      )

    {:ok,
     %{
       pid: pid,
       monitor: monitor,
       token: token,
       sequence: 0,
       alive: true,
       failure: nil,
       pages_sent: 0,
       pages_received: 0,
       jobs_sent: 0,
       results_received: 0,
       messages_sent: 0,
       messages_received: 0,
       request_bytes: byte_counter(),
       result_bytes: byte_counter(),
       page_durations_ms: [],
       inventory_count: 0,
       inventory_peak: 0,
       inventory_pages_sent: 0,
       inventory_pages_received: 0,
       inventory_items_sent: 0,
       inventory_messages_sent: 0,
       inventory_messages_received: 0,
       inventory_request_bytes: byte_counter(),
       inventory_result_bytes: byte_counter()
     }}
  end

  def register_page(session, leases, timeout),
    do: inventory_command(session, :register, leases, timeout)

  def replace_page(session, leases, timeout),
    do: inventory_command(session, :replace, leases, timeout)

  def drop_page(session, identities, timeout),
    do: inventory_command(session, :drop, identities, timeout)

  def reset_cleanup_stats(session) do
    Map.merge(session, %{
      pages_sent: 0,
      pages_received: 0,
      jobs_sent: 0,
      results_received: 0,
      messages_sent: 0,
      messages_received: 0,
      request_bytes: byte_counter(),
      result_bytes: byte_counter(),
      page_durations_ms: []
    })
  end

  def page(%{alive: true} = session, [], _timeout), do: {:ok, [], session}

  def page(%{alive: true} = session, jobs, timeout)
      when is_list(jobs) and length(jobs) <= @maximum_page_size and is_integer(timeout) and
             timeout > 0 do
    sequence = session.sequence + 1
    started = System.monotonic_time(:millisecond)
    send(session.pid, {session.token, :page, sequence, jobs})

    sent = %{
      session
      | sequence: sequence,
        pages_sent: session.pages_sent + 1,
        jobs_sent: session.jobs_sent + length(jobs),
        messages_sent: session.messages_sent + 1,
        request_bytes: add_encoded_size(session.request_bytes, jobs)
    }

    receive do
      {token, :page_result, ^sequence, results} when token == session.token ->
        if valid_results?(results, length(jobs)) do
          received = %{
            sent
            | pages_received: sent.pages_received + 1,
              results_received: sent.results_received + length(results),
              messages_received: sent.messages_received + 1,
              result_bytes: add_encoded_size(sent.result_bytes, results),
              page_durations_ms: [
                System.monotonic_time(:millisecond) - started | sent.page_durations_ms
              ]
          }

          {:ok, Enum.map(results, &elem(&1, 1)), received}
        else
          {:error, :malformed_reply, terminate_session(%{sent | failure: :malformed_reply})}
        end

      {:DOWN, monitor, :process, pid, _}
      when monitor == session.monitor and pid == session.pid ->
        flush_exit(session.pid)

        {:error, :port_failed,
         %{
           sent
           | alive: false,
             failure: :port_failed,
             messages_received: sent.messages_received + 1
         }}
    after
      timeout ->
        {:error, :timed_out, terminate_session(%{sent | failure: :timed_out})}
    end
  end

  def page(%{alive: true} = session, _jobs, _timeout),
    do: {:error, :invalid_page, terminate_session(%{session | failure: :invalid_page})}

  def page(session, _jobs, _timeout),
    do: {:error, Map.get(session, :failure) || :port_failed, session}

  def release_page(%{alive: true} = session, port, leases, timeout)
      when is_list(leases) and leases != [] and length(leases) <= @page_size and
             is_integer(timeout) and timeout > 0 do
    sequence = session.sequence + 1
    started = System.monotonic_time(:millisecond)
    send(session.pid, {session.token, :release_page, sequence, port, leases})

    sent = %{
      session
      | sequence: sequence,
        pages_sent: session.pages_sent + 1,
        jobs_sent: session.jobs_sent + length(leases),
        messages_sent: session.messages_sent + 1,
        request_bytes: add_encoded_size(session.request_bytes, {port, leases})
    }

    receive do
      {token, :release_result, ^sequence, results} when token == session.token ->
        if is_list(results) and length(results) == length(leases) do
          received = %{
            sent
            | pages_received: sent.pages_received + 1,
              results_received: sent.results_received + length(results),
              messages_received: sent.messages_received + 1,
              result_bytes: add_encoded_size(sent.result_bytes, results),
              page_durations_ms: [
                System.monotonic_time(:millisecond) - started | sent.page_durations_ms
              ]
          }

          {:ok, results, received}
        else
          {:error, :malformed_reply, terminate_session(%{sent | failure: :malformed_reply})}
        end

      {:DOWN, monitor, :process, pid, _}
      when monitor == session.monitor and pid == session.pid ->
        flush_exit(session.pid)
        {:error, :port_failed, %{sent | alive: false, failure: :port_failed}}
    after
      timeout ->
        {:error, :timed_out, terminate_session(%{sent | failure: :timed_out})}
    end
  end

  def release_page(session, _port, _leases, _timeout),
    do: {:error, Map.get(session, :failure) || :invalid_page, session}

  def release_owned_page(%{alive: true} = session, port, identities, timeout)
      when is_list(identities) and identities != [] and length(identities) <= @page_size and
             is_integer(timeout) and timeout > 0 do
    sequence = session.sequence + 1
    started = System.monotonic_time(:millisecond)
    send(session.pid, {session.token, :release_owned_page, sequence, port, identities})

    sent = %{
      session
      | sequence: sequence,
        pages_sent: session.pages_sent + 1,
        jobs_sent: session.jobs_sent + length(identities),
        messages_sent: session.messages_sent + 1,
        request_bytes: add_encoded_size(session.request_bytes, {port, identities})
    }

    receive do
      {token, :release_owned_result, ^sequence, results, inventory_count}
      when token == session.token ->
        if is_list(results) and length(results) == length(identities) and
             is_integer(inventory_count) and inventory_count in 0..512 do
          received = %{
            sent
            | pages_received: sent.pages_received + 1,
              results_received: sent.results_received + length(results),
              messages_received: sent.messages_received + 1,
              result_bytes: add_encoded_size(sent.result_bytes, results),
              page_durations_ms: [
                System.monotonic_time(:millisecond) - started | sent.page_durations_ms
              ],
              inventory_count: inventory_count
          }

          {:ok, results, received}
        else
          {:error, :malformed_reply, terminate_session(%{sent | failure: :malformed_reply})}
        end

      {:DOWN, monitor, :process, pid, _}
      when monitor == session.monitor and pid == session.pid ->
        flush_exit(session.pid)
        {:error, :port_failed, %{sent | alive: false, failure: :port_failed}}
    after
      timeout ->
        {:error, :timed_out, terminate_session(%{sent | failure: :timed_out})}
    end
  end

  def release_owned_page(session, _port, _identities, _timeout),
    do: {:error, Map.get(session, :failure) || :invalid_page, session}

  def close_session(%{alive: false} = session), do: session

  def close_session(session) do
    Process.unlink(session.pid)

    if Process.alive?(session.pid) do
      send(session.pid, {session.token, :stop})

      receive do
        {:DOWN, monitor, :process, pid, _}
        when monitor == session.monitor and pid == session.pid ->
          :ok
      after
        100 ->
          Process.exit(session.pid, :kill)

          receive do
            {:DOWN, monitor, :process, pid, _}
            when monitor == session.monitor and pid == session.pid ->
              :ok
          after
            0 -> Process.demonitor(session.monitor, [:flush])
          end
      end
    else
      Process.demonitor(session.monitor, [:flush])
    end

    flush_exit(session.pid)
    flush_session(session.token)
    %{session | alive: false}
  end

  def terminate_session(%{alive: false} = session), do: session

  def terminate_session(session) do
    Process.unlink(session.pid)
    Process.exit(session.pid, :kill)

    receive do
      {:DOWN, monitor, :process, pid, _}
      when monitor == session.monitor and pid == session.pid ->
        :ok
    end

    flush_exit(session.pid)
    flush_session(session.token)
    %{session | alive: false}
  end

  def session_stats(session) do
    Map.take(session, [
      :pages_sent,
      :pages_received,
      :jobs_sent,
      :results_received,
      :messages_sent,
      :messages_received,
      :request_bytes,
      :result_bytes,
      :page_durations_ms
    ])
  end

  def inventory_stats(session) do
    Map.take(session, [
      :inventory_count,
      :inventory_peak,
      :inventory_pages_sent,
      :inventory_pages_received,
      :inventory_items_sent,
      :inventory_messages_sent,
      :inventory_messages_received,
      :inventory_request_bytes,
      :inventory_result_bytes
    ])
  end

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

  defp flush_session(token) do
    receive do
      {^token, _, _, _} -> flush_session(token)
    after
      0 -> :ok
    end
  end

  defp byte_counter do
    if :erlang.system_info(:machine) == ~c"BEAM", do: 0, else: :unavailable
  rescue
    _ -> :unavailable
  catch
    _, _ -> :unavailable
  end

  defp add_encoded_size(current, value) when is_integer(current),
    do: current + :erlang.external_size(value)

  defp add_encoded_size(_, _), do: :unavailable

  defp inventory_command(%{alive: true} = session, operation, items, timeout)
       when operation in [:register, :replace, :drop] and is_list(items) and items != [] and
              length(items) <= @maximum_page_size and is_integer(timeout) and timeout > 0 do
    sequence = session.sequence + 1
    send(session.pid, {session.token, :inventory, sequence, operation, items})

    sent = %{
      session
      | sequence: sequence,
        inventory_pages_sent: session.inventory_pages_sent + 1,
        inventory_items_sent: session.inventory_items_sent + length(items),
        inventory_messages_sent: session.inventory_messages_sent + 1,
        inventory_request_bytes: add_encoded_size(session.inventory_request_bytes, items)
    }

    receive do
      {token, :inventory_result, ^sequence, result, inventory_count}
      when token == session.token ->
        if result in [:ok, :invalid_inventory] and is_integer(inventory_count) and
             inventory_count in 0..512 do
          received = %{
            sent
            | inventory_count: inventory_count,
              inventory_peak: max(sent.inventory_peak, inventory_count),
              inventory_pages_received: sent.inventory_pages_received + 1,
              inventory_messages_received: sent.inventory_messages_received + 1,
              inventory_result_bytes:
                add_encoded_size(sent.inventory_result_bytes, {result, inventory_count})
          }

          if result == :ok,
            do: {:ok, received},
            else: {:error, result, received}
        else
          {:error, :malformed_reply, terminate_session(%{sent | failure: :malformed_reply})}
        end

      {:DOWN, monitor, :process, pid, _}
      when monitor == session.monitor and pid == session.pid ->
        flush_exit(session.pid)
        {:error, :port_failed, %{sent | alive: false, failure: :port_failed}}
    after
      timeout ->
        {:error, :timed_out, terminate_session(%{sent | failure: :timed_out})}
    end
  end

  defp inventory_command(%{alive: true} = session, _operation, _items, _timeout),
    do: {:error, :invalid_inventory, session}

  defp inventory_command(session, _operation, _items, _timeout),
    do: {:error, Map.get(session, :failure) || :port_failed, session}

  defp session_loop(owner, token, owner_monitor, inventory) do
    receive do
      {^token, :page, sequence, jobs}
      when is_integer(sequence) and is_list(jobs) and length(jobs) <= @maximum_page_size ->
        results =
          jobs
          |> RootPort.call_page()
          |> Enum.with_index()
          |> Enum.map(fn {result, index} -> {index, result} end)

        send(owner, {token, :page_result, sequence, results})
        session_loop(owner, token, owner_monitor, inventory)

      {^token, :release_page, sequence, port, leases}
      when is_integer(sequence) and is_list(leases) and leases != [] and
             length(leases) <= @page_size ->
        results = RootPort.release_page(port, leases)
        send(owner, {token, :release_result, sequence, results})
        session_loop(owner, token, owner_monitor, inventory)

      {^token, :inventory, sequence, operation, items}
      when is_integer(sequence) and operation in [:register, :replace, :drop] and
             is_list(items) and items != [] and length(items) <= @maximum_page_size ->
        case update_inventory(inventory, operation, items) do
          {:ok, next_inventory} ->
            send(owner, {token, :inventory_result, sequence, :ok, map_size(next_inventory)})
            session_loop(owner, token, owner_monitor, next_inventory)

          :error ->
            send(
              owner,
              {token, :inventory_result, sequence, :invalid_inventory, map_size(inventory)}
            )

            session_loop(owner, token, owner_monitor, inventory)
        end

      {^token, :release_owned_page, sequence, port, identities}
      when is_integer(sequence) and is_list(identities) and identities != [] and
             length(identities) <= @page_size ->
        if valid_identity_page?(identities) and
             Enum.all?(identities, &Map.has_key?(inventory, &1)) do
          leases = Enum.map(identities, &Map.fetch!(inventory, &1))
          results = RootPort.release_page(port, leases)

          completed =
            identities
            |> Enum.zip(results)
            |> Enum.flat_map(fn
              {identity, :released} -> [identity]
              _ -> []
            end)

          next_inventory = Map.drop(inventory, completed)
          send(owner, {token, :release_owned_result, sequence, results, map_size(next_inventory)})
          session_loop(owner, token, owner_monitor, next_inventory)
        else
          results = List.duplicate({:error, :inventory_mismatch}, length(identities))
          send(owner, {token, :release_owned_result, sequence, results, map_size(inventory)})
          session_loop(owner, token, owner_monitor, inventory)
        end

      {^token, :stop} ->
        :ok

      {:DOWN, ^owner_monitor, :process, ^owner, _} ->
        :ok

      _ ->
        session_loop(owner, token, owner_monitor, inventory)
    end
  end

  defp update_inventory(inventory, :register, leases) do
    if valid_lease_page?(leases) and map_size(inventory) + length(leases) <= 512 and
         Enum.all?(leases, &(not Map.has_key?(inventory, &1.id))) do
      {:ok, Enum.reduce(leases, inventory, &Map.put(&2, &1.id, &1))}
    else
      :error
    end
  end

  defp update_inventory(inventory, :replace, leases) do
    if valid_lease_page?(leases) and Enum.all?(leases, &Map.has_key?(inventory, &1.id)) do
      {:ok, Enum.reduce(leases, inventory, &Map.put(&2, &1.id, &1))}
    else
      :error
    end
  end

  defp update_inventory(inventory, :drop, identities) do
    if valid_identity_page?(identities) and Enum.all?(identities, &Map.has_key?(inventory, &1)) do
      {:ok, Map.drop(inventory, identities)}
    else
      :error
    end
  end

  defp valid_lease_page?(leases) do
    identities = Enum.map(leases, &Map.get(&1, :id))

    Enum.all?(leases, &(is_map(&1) and is_binary(Map.get(&1, :id)))) and
      valid_identity_page?(identities)
  rescue
    _ -> false
  end

  defp valid_identity_page?(identities),
    do:
      Enum.all?(identities, &is_binary/1) and length(Enum.uniq(identities)) == length(identities)

  defp valid_results?(results, count) when is_list(results),
    do: length(results) == count and indexed_results?(results, 0)

  defp valid_results?(_, _), do: false
  defp indexed_results?([], _index), do: true
  defp indexed_results?([{index, _} | rest], index), do: indexed_results?(rest, index + 1)
  defp indexed_results?(_, _index), do: false

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
