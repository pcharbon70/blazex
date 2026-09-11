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
      version: 1,
      kind: :lease,
      identities: Enum.map(leases, &{&1.owner, &1.id}),
      status: compact(statuses),
      force_status: :not_requested,
      unresolved: compact(Enum.map(statuses, &(&1 != :completed))),
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

    %{page | force_status: compact(force_statuses), unresolved: compact(unresolved)}
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
        count = length(page.identities)

        page.identities
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {identity, index}, inner ->
          if value(page.unresolved, index, count), do: [identity | inner], else: inner
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
    Enum.reduce(pages, empty_counts(), fn
      %{kind: :lease} = page, acc -> count_lease_page(page, acc)
      %{kind: :operations, rows: rows}, acc -> Enum.reduce(rows, acc, &count_row/2)
    end)
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
        %{kind: :lease, identities: values} -> values
        _ -> []
      end)

    length(identities) == length(leases) and
      Enum.zip_reduce(identities, leases, true, fn {owner, id}, lease, acc ->
        acc and lease.id == id and lease.owner == owner
      end)
  end

  def representation(pages) do
    lease_pages = Enum.filter(pages, &(&1.kind == :lease))

    %{
      version: 1,
      outcome_pages: length(lease_pages),
      identities: Enum.sum(Enum.map(lease_pages, &length(&1.identities))),
      vectors:
        Enum.sum(
          Enum.map(lease_pages, fn page ->
            Enum.count([page.status, page.force_status, page.unresolved], &is_list/1)
          end)
        ),
      expanded_rows: 0,
      encoded_bytes: safe_bytes(lease_pages)
    }
  end

  def valid_page?(%{version: 1, kind: :operations, rows: rows}) do
    is_list(rows) and rows != [] and length(rows) <= @page_size and
      Enum.all?(rows, &operation_row?/1)
  end

  def valid_page?(%{
        version: 1,
        kind: :lease,
        identities: identities,
        status: status,
        force_status: force_status,
        unresolved: unresolved,
        elapsed_ms: elapsed_ms
      }) do
    count = if is_list(identities), do: length(identities), else: 0

    count in 1..@page_size and is_integer(elapsed_ms) and elapsed_ms >= 0 and
      Enum.all?(identities, &identity?/1) and field?(status, count, @statuses) and
      field?(force_status, count, @force_statuses) and field?(unresolved, count, [true, false])
  end

  def valid_page?(_), do: false

  defp fold_lease_page(page, initial, fun) do
    count = length(page.identities)

    page.identities
    |> Enum.with_index()
    |> Enum.reduce(initial, fn {{owner, id}, index}, acc ->
      fun.(
        %{
          owner: owner,
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

  defp identity?({owner, id}), do: is_map(owner) and is_binary(id) and byte_size(id) in 1..64
  defp identity?(_), do: false

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

  defp empty_counts,
    do: %{requested: 0, failed: 0, timed_out: 0, forced: 0, unresolved: 0}

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
    %{
      requested: acc.requested + 1,
      failed: acc.failed + truth(status == :failed),
      timed_out: acc.timed_out + truth(status == :timed_out),
      forced: acc.forced + truth(force_status == :completed),
      unresolved: acc.unresolved + truth(unresolved)
    }
  end

  defp safe_bytes(value) do
    byte_size(:erlang.term_to_binary(value))
  rescue
    _ -> :unavailable
  catch
    _, _ -> :unavailable
  end
end
