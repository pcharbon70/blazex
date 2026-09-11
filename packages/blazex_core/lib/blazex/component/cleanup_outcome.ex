defmodule BlazeX.Component.CleanupOutcome do
  @moduledoc false

  @page_size 64
  @maximum_items 512
  @statuses [:completed, :failed, :timed_out]
  @force_statuses [:not_requested | @statuses]

  def lease_page(leases, statuses, elapsed_ms)
      when is_list(leases) and is_list(statuses) and is_integer(elapsed_ms) and elapsed_ms >= 0 do
    true = leases != [] and length(leases) <= @page_size and length(leases) == length(statuses)
    true = Enum.all?(statuses, &(&1 in @statuses))

    page = %{
      version: 2,
      kind: :lease,
      identities: Enum.map(leases, & &1.id),
      status: compact(statuses),
      force_status: :not_requested,
      unresolved: compact(Enum.map(statuses, &(&1 != :completed))),
      unresolved_owners:
        leases
        |> Enum.zip(statuses)
        |> Enum.with_index()
        |> Enum.flat_map(fn
          {{_lease, :completed}, _index} -> []
          {{lease, _status}, index} -> [{index, lease.owner}]
        end),
      elapsed_ms: elapsed_ms
    }

    true = valid_page?(page)
    page
  end

  def operation_pages(rows) when is_list(rows) do
    rows
    |> Enum.chunk_every(@page_size)
    |> Enum.map(fn page -> %{version: 1, kind: :operations, rows: page} end)
  end

  def apply_force(page, updates) when is_map(updates) do
    true = valid_page?(page) and page.kind == :lease
    count = length(page.identities)

    force_statuses =
      Enum.map(0..(count - 1), fn index ->
        Map.get(updates, index, value(page.force_status, index, count))
      end)

    true = Enum.all?(force_statuses, &(&1 in @force_statuses))

    unresolved =
      Enum.map(0..(count - 1), fn index ->
        value(page.status, index, count) != :completed and
          Enum.at(force_statuses, index) != :completed
      end)

    unresolved_owners =
      Enum.filter(page.unresolved_owners, fn {index, _owner} -> Enum.at(unresolved, index) end)

    %{
      page
      | force_status: compact(force_statuses),
        unresolved: compact(unresolved),
        unresolved_owners: unresolved_owners
    }
  end

  def fold(pages, initial, fun) when is_list(pages) and is_function(fun, 2) do
    true = item_count(pages) <= @maximum_items + 257

    Enum.reduce(pages, initial, fn page, acc ->
      true = valid_page?(page)

      case page.kind do
        :operations -> Enum.reduce(page.rows, acc, fun)
        :lease -> fold_lease_page(page, acc, fun)
      end
    end)
  end

  def rows(pages), do: fold(pages, [], fn row, acc -> [row | acc] end) |> Enum.reverse()

  def unresolved_identities(pages) do
    Enum.reduce(pages, [], fn
      %{kind: :lease} = page, acc ->
        true = valid_page?(page)

        Enum.reduce(page.unresolved_owners, acc, fn {index, owner}, inner ->
          [{owner, Enum.fetch!(page.identities, index)} | inner]
        end)

      %{kind: :operations, rows: rows}, acc ->
        Enum.reduce(rows, acc, fn row, inner ->
          if row.unresolved, do: [{row.owner, row.reference} | inner], else: inner
        end)
    end)
    |> Enum.reverse()
  end

  def terminal_statuses(pages) do
    Enum.reduce(pages, [], fn
      %{kind: :lease} = page, acc ->
        count = length(page.identities)

        Enum.reduce(0..(count - 1), acc, fn index, inner ->
          [if(value(page.unresolved, index, count), do: :lost, else: :released) | inner]
        end)

      _, acc ->
        acc
    end)
    |> Enum.reverse()
  end

  def counts(pages) do
    {requested, failed, timed_out, forced, unresolved} =
      Enum.reduce(pages, {0, 0, 0, 0, 0}, fn
        %{kind: :lease} = page, acc -> count_lease_page(page, acc)
        %{kind: :operations, rows: rows}, acc -> Enum.reduce(rows, acc, &count_row/2)
      end)

    %{
      requested: requested,
      failed: failed,
      timed_out: timed_out,
      forced: forced,
      unresolved: unresolved
    }
  end

  def callback_failures(pages) do
    Enum.reduce(pages, 0, fn
      %{kind: :operations, rows: rows}, acc ->
        acc + Enum.count(rows, &(&1.kind == :component and &1.status != :completed))

      _, acc ->
        acc
    end)
  end

  def matches_leases?(pages, leases) when is_list(pages) and is_list(leases) do
    identities =
      Enum.flat_map(pages, fn
        %{kind: :lease} = page ->
          true = valid_page?(page)
          owners = Map.new(page.unresolved_owners)
          Enum.with_index(page.identities, fn id, index -> {id, Map.get(owners, index)} end)

        _ ->
          []
      end)

    length(identities) == length(leases) and
      Enum.zip_reduce(identities, leases, true, fn {id, owner}, lease, acc ->
        acc and lease.id == id and (owner == nil or lease.owner == owner)
      end)
  end

  def terminal_summary(pages, leases) when is_list(pages) and is_list(leases) do
    total = length(leases)

    {remaining, released, lost, history, count} =
      Enum.reduce(pages, {leases, 0, 0, [], 0}, fn
        %{kind: :lease} = page, acc -> summarize_page(page, acc, total)
        _, acc -> acc
      end)

    true = remaining == [] and count == total

    %{count: count, released: released, lost: lost, history: Enum.reverse(history)}
  end

  def representation(pages) do
    lease_pages = Enum.filter(pages, &(&1.kind == :lease))

    %{
      version: 2,
      outcome_pages: length(lease_pages),
      identities: Enum.sum(Enum.map(lease_pages, &length(&1.identities))),
      vectors:
        Enum.sum(
          Enum.map(lease_pages, fn page ->
            Enum.count([page.status, page.force_status, page.unresolved], &is_list/1)
          end)
        ),
      owner_records: Enum.sum(Enum.map(lease_pages, &length(&1.unresolved_owners))),
      expanded_rows: 0,
      encoded_bytes: safe_bytes(lease_pages)
    }
  end

  def valid_page?(%{version: 1, kind: :operations, rows: rows}) do
    is_list(rows) and rows != [] and length(rows) <= @page_size and
      Enum.all?(rows, &operation_row?/1)
  end

  def valid_page?(%{
        version: 2,
        kind: :lease,
        identities: identities,
        status: status,
        force_status: force_status,
        unresolved: unresolved,
        unresolved_owners: unresolved_owners,
        elapsed_ms: elapsed_ms
      }) do
    count = if is_list(identities), do: length(identities), else: 0

    count in 1..@page_size and is_integer(elapsed_ms) and elapsed_ms >= 0 and
      Enum.all?(identities, &identity?/1) and field?(status, count, @statuses) and
      field?(force_status, count, @force_statuses) and field?(unresolved, count, [true, false]) and
      sparse_owners?(unresolved_owners, unresolved, count)
  end

  def valid_page?(_), do: false

  defp fold_lease_page(page, initial, fun) do
    count = length(page.identities)
    owners = Map.new(page.unresolved_owners)

    page.identities
    |> Enum.with_index()
    |> Enum.reduce(initial, fn {id, index}, acc ->
      fun.(
        %{
          owner: Map.get(owners, index),
          kind: :lease,
          reference: %{id: id},
          requested: true,
          status: value(page.status, index, count),
          force_status: value(page.force_status, index, count),
          elapsed_ms: page.elapsed_ms,
          unresolved: value(page.unresolved, index, count)
        },
        acc
      )
    end)
  end

  defp compact([head | tail] = values) do
    if Enum.all?(tail, &(&1 == head)), do: head, else: values
  end

  defp value(values, index, count) when is_list(values) do
    true = length(values) == count
    Enum.fetch!(values, index)
  end

  defp value(value, _index, _count), do: value

  defp field?(values, count, allowed) when is_list(values),
    do: length(values) == count and Enum.all?(values, &(&1 in allowed))

  defp field?(value, _count, allowed), do: value in allowed

  defp identity?(id) when is_binary(id), do: byte_size(id) in 1..64
  defp identity?(_), do: false

  defp sparse_owners?(owners, unresolved, count) when is_list(owners) do
    expected = Enum.filter(0..(count - 1), &value(unresolved, &1, count))

    Enum.map(owners, &elem(&1, 0)) == expected and
      Enum.all?(owners, fn
        {index, owner} -> is_integer(index) and index in 0..(count - 1) and is_map(owner)
        _ -> false
      end)
  rescue
    _ -> false
  end

  defp sparse_owners?(_, _, _), do: false

  defp operation_row?(row) do
    is_map(row) and row.kind != :lease and row.status in @statuses and
      row.force_status in @force_statuses and is_boolean(row.unresolved)
  rescue
    _ -> false
  end

  defp item_count(pages) do
    Enum.sum(
      Enum.map(pages, fn
        %{kind: :lease, identities: identities} when is_list(identities) -> length(identities)
        %{kind: :operations, rows: rows} when is_list(rows) -> length(rows)
        _ -> @maximum_items + 129
      end)
    )
  end

  defp truth(true), do: 1
  defp truth(false), do: 0

  defp count_lease_page(page, acc) do
    count = length(page.identities)

    Enum.reduce(0..(count - 1), acc, fn index, current ->
      count_values(
        current,
        value(page.status, index, count),
        value(page.force_status, index, count),
        value(page.unresolved, index, count)
      )
    end)
  end

  defp count_row(row, acc),
    do: count_values(acc, row.status, row.force_status, row.unresolved)

  defp count_values(acc, status, force_status, unresolved) do
    {requested, failed, timed_out, forced, unresolved_count} = acc

    {
      requested + 1,
      failed + truth(status == :failed),
      timed_out + truth(status == :timed_out),
      forced + truth(force_status == :completed),
      unresolved_count + truth(unresolved)
    }
  end

  defp summarize_page(page, {leases, released, lost, history, offset}, total) do
    count = length(page.identities)

    summarize_identities(
      page.identities,
      leases,
      page.unresolved,
      Map.new(page.unresolved_owners),
      count,
      0,
      released,
      lost,
      history,
      offset,
      total
    )
  end

  defp summarize_identities(
         [],
         leases,
         _unresolved,
         _owners,
         _count,
         _index,
         released,
         lost,
         history,
         position,
         _total
       ),
       do: {leases, released, lost, history, position}

  defp summarize_identities(
         [id | identities],
         [lease | leases],
         unresolved,
         owners,
         count,
         index,
         released,
         lost,
         history,
         position,
         total
       ) do
    true = lease.id == id
    status = if value(unresolved, index, count), do: :lost, else: :released
    true = status == :released or Map.fetch!(owners, index) == lease.owner

    history =
      if position >= total - 128 do
        [{status, lease.id, lease.acquisition} | history]
      else
        history
      end

    {released, lost} =
      case status do
        :released -> {released + 1, lost}
        :lost -> {released, lost + 1}
      end

    summarize_identities(
      identities,
      leases,
      unresolved,
      owners,
      count,
      index + 1,
      released,
      lost,
      history,
      position + 1,
      total
    )
  end

  defp safe_bytes(value) do
    if :erlang.system_info(:machine) == ~c"BEAM",
      do: byte_size(:erlang.term_to_binary(value)),
      else: :unavailable
  rescue
    _ -> :unavailable
  catch
    _, _ -> :unavailable
  end
end
