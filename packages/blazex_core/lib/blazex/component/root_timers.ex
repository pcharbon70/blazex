defmodule BlazeX.Component.RootTimers do
  @moduledoc false
  alias BlazeX.Component.{NestedTable, RootSchedule}
  defstruct entries: %{}, serial: 0, completed: 0, canceled: 0, rejected: 0

  def key(item), do: {item.source, item.timer.id}

  def refs(timers),
    do: timers.entries |> Map.values() |> Enum.map(& &1.reference) |> Enum.reject(&is_nil/1)

  def preflight(timers, intents) do
    if NestedTable.counter?(timers.serial + Enum.count(intents, &(&1.kind == :timer_start))),
      do: preflight_keys(timers, intents),
      else: {:error, :timer_limit_or_duplicate}
  end

  defp preflight_keys(timers, intents) do
    Enum.reduce_while(intents, {:ok, Map.keys(timers.entries) |> MapSet.new()}, fn item,
                                                                                   {:ok, keys} ->
      cond do
        item.kind == :message ->
          {:cont, {:ok, keys}}

        item.kind == :timer_cancel ->
          {:cont, {:ok, MapSet.delete(keys, key(item))}}

        item.kind == :timer_start and not MapSet.member?(keys, key(item)) and
            MapSet.size(keys) < 32 ->
          {:cont, {:ok, MapSet.put(keys, key(item))}}

        true ->
          {:halt, {:error, :timer_limit_or_duplicate}}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  def install(timers, %{kind: :timer_start} = item) do
    if preflight(timers, [item]) == :ok and NestedTable.counter?(timers.serial + 1) do
      epoch = timers.serial + 1
      token = make_ref()
      entry = %{item: item, epoch: epoch, token: token, tick: 0, status: :waiting, reference: nil}

      reference =
        Process.send_after(self(), {:owned_tick, key(item), epoch, token}, item.timer.delay)

      {:ok,
       %{
         timers
         | entries: Map.put(timers.entries, key(item), %{entry | reference: reference}),
           serial: epoch
       }}
    else
      {:error, :timer_limit_or_duplicate}
    end
  end

  def cancel(timers, key) do
    case Map.pop(timers.entries, key) do
      {nil, _} ->
        timers

      {entry, rest} ->
        if entry.reference, do: Process.cancel_timer(entry.reference)
        %{timers | entries: rest, canceled: bump(timers.canceled)}
    end
  end

  def cancel_all(timers), do: Enum.reduce(Map.keys(timers.entries), timers, &cancel(&2, &1))

  def prune(timers, accepted) do
    Enum.reduce(timers.entries, timers, fn {key, entry}, acc ->
      if RootSchedule.valid_dispatch?(entry.item, accepted), do: acc, else: cancel(acc, key)
    end)
  end

  def wake(timers, key, epoch, token, accepted) do
    case Map.get(timers.entries, key) do
      %{epoch: ^epoch, token: ^token, status: :waiting} = entry ->
        if RootSchedule.valid_dispatch?(entry.item, accepted) and
             NestedTable.counter?(entry.tick + 1) do
          item = %{
            entry.item
            | kind: :timer_tick,
              origin: :timer,
              revision: accepted.correlation.revision,
              timer: %{id: entry.item.timer.id, epoch: epoch, tick: entry.tick + 1}
          }

          updated = %{entry | tick: entry.tick + 1, status: :firing, reference: nil}
          {:ok, item, %{timers | entries: Map.put(timers.entries, key, updated)}}
        else
          {:error, cancel(timers, key)}
        end

      _ ->
        {:error, %{timers | rejected: bump(timers.rejected)}}
    end
  end

  def valid_tick?(timers, %{kind: :timer_tick} = item) do
    case Map.get(timers.entries, key(item)) do
      %{epoch: epoch, tick: tick, status: :firing} ->
        epoch == item.timer.epoch and tick == item.timer.tick

      _ ->
        false
    end
  end

  def valid_tick?(_, _), do: true

  def finish(timers, %{kind: :timer_tick} = item) do
    if valid_tick?(timers, item) do
      entry = Map.fetch!(timers.entries, key(item))

      if entry.item.timer.interval do
        token = make_ref()

        reference =
          Process.send_after(
            self(),
            {:owned_tick, key(item), entry.epoch, token},
            entry.item.timer.interval
          )

        next = %{entry | token: token, status: :waiting, reference: reference}
        %{timers | entries: Map.put(timers.entries, key(item), next)}
      else
        %{
          timers
          | entries: Map.delete(timers.entries, key(item)),
            completed: bump(timers.completed)
        }
      end
    else
      timers
    end
  end

  def finish(timers, _), do: timers

  defp bump(value), do: min(value + 1, 9_007_199_254_740_991)

  def inventory(timers) do
    %{
      active: map_size(timers.entries),
      completed: timers.completed,
      canceled: timers.canceled,
      rejected: timers.rejected,
      entries:
        timers.entries
        |> Enum.map(fn {{owner, id}, entry} ->
          %{
            owner: owner,
            id: id,
            generation: owner.generation,
            epoch: entry.epoch,
            tick: entry.tick,
            status: entry.status,
            repeating: entry.item.timer.interval != nil
          }
        end)
        |> Enum.sort_by(&{&1.owner, &1.id})
    }
  end
end
