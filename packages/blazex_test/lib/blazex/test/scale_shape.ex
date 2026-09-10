defmodule BlazeX.Test.ScaleShape do
  @moduledoc """
  Deterministic, backend-neutral scaling workload and robust shape analysis.

  Raw observations remain authoritative. This module never removes failures or
  outliers and reports alarms separately from harness execution.
  """

  @cleanup_counts [0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512]
  @maximum_payload_counts [64, 65, 256, 512]
  @minimal_payload_counts [64, 512]

  def cleanup_contract do
    %{
      counts: @cleanup_counts,
      maximum_payload_counts: @maximum_payload_counts,
      minimal_payload_counts: @minimal_payload_counts,
      page_size: 64,
      maximum_page_size: 128,
      warmups: 1,
      repetitions: %{
        erts: %{default: 20, endpoint: 100},
        chrome: %{default: 10, endpoint: 20},
        firefox: %{default: 10, endpoint: 20}
      },
      endpoint: 512,
      alarm: %{absolute_ms: 100, ratio: 0.5, minimum_count: 64}
    }
  end

  def cleanup_workloads(runtime) when runtime in [:erts, :chrome, :firefox] do
    config = cleanup_contract()

    payloads =
      Enum.map(@cleanup_counts, &{:canonical, &1}) ++
        Enum.map(@maximum_payload_counts, &{:maximum, &1}) ++
        Enum.map(@minimal_payload_counts, &{:minimal, &1})

    payloads
    |> Enum.flat_map(fn {payload_class, count} ->
      repetitions =
        if count == config.endpoint,
          do: config.repetitions[runtime].endpoint,
          else: config.repetitions[runtime].default

      Enum.map(1..repetitions, fn sample ->
        %{
          runtime: runtime,
          payload_class: payload_class,
          count: count,
          sample: sample,
          retained: true
        }
      end)
    end)
  end

  def analyze(records, options \\ []) when is_list(records) and is_list(options) do
    x_key = Keyword.get(options, :x_key, :count)
    y_key = Keyword.get(options, :y_key, :elapsed_ms)
    group_keys = Keyword.get(options, :group_keys, [:runtime, :payload_class])
    minimum_x = Keyword.get(options, :minimum_x, 64)
    absolute = Keyword.get(options, :absolute_alarm, 100)
    ratio = Keyword.get(options, :relative_alarm, 0.5)

    records
    |> Enum.group_by(fn record -> Enum.map(group_keys, &Map.fetch!(record, &1)) end)
    |> Enum.map(fn {group, observations} ->
      points =
        observations
        |> Enum.group_by(&Map.fetch!(&1, x_key))
        |> Enum.map(fn {x, samples} ->
          values = Enum.map(samples, &Map.fetch!(&1, y_key))
          %{x: x, median: median(values), p95: nearest_rank(values, 95), samples: length(values)}
        end)
        |> Enum.sort_by(& &1.x)

      fitted = Enum.filter(points, &(&1.x >= minimum_x))
      {slope, intercept} = theil_sen(Enum.map(fitted, &{&1.x, &1.median}))

      alarms =
        Enum.flat_map(fitted, fn point ->
          predicted = intercept + slope * point.x
          envelope = max(absolute, abs(predicted) * ratio)

          if point.median > predicted + envelope do
            [
              %{
                x: point.x,
                observed: point.median,
                predicted: predicted,
                envelope: envelope
              }
            ]
          else
            []
          end
        end)

      %{
        group: Enum.zip(group_keys, group) |> Map.new(),
        points: points,
        model: %{method: :theil_sen, slope: slope, intercept: intercept},
        alarms: alarms
      }
    end)
    |> Enum.sort_by(& &1.group)
  end

  def cleanup_structural_errors(%{count: count, amplification: amplification}) do
    expected_lease_pages = div(count + amplification.page_size - 1, amplification.page_size)
    normal = amplification.normal
    forced = amplification.forced
    total_pages = normal.pages_sent + forced.pages_sent

    []
    |> error_unless(amplification.page_size == 64, :page_size_changed)
    |> error_unless(amplification.maximum_page_size == 128, :maximum_page_size_changed)
    |> error_unless(amplification.normal_worker_starts <= 1, :normal_worker_amplification)
    |> error_unless(amplification.forced_worker_starts <= 1, :forced_worker_amplification)
    |> error_unless(amplification.total_worker_starts <= 2, :total_worker_amplification)
    |> error_unless(amplification.peak_live_cleanup_workers <= 1, :concurrent_worker_growth)
    |> error_unless(amplification.lease_pages_sent == expected_lease_pages, :lease_page_mismatch)
    |> error_unless(amplification.protocol_messages <= total_pages * 2, :message_amplification)
    |> Enum.reverse()
  end

  def nearest_rank(values, percentile)
      when is_list(values) and values != [] and is_integer(percentile) and percentile in 1..100 do
    sorted = Enum.sort(values)
    index = div(percentile * length(sorted) + 99, 100) - 1
    Enum.at(sorted, index)
  end

  def median(values) when is_list(values) and values != [] do
    sorted = Enum.sort(values)
    count = length(sorted)
    middle = div(count, 2)

    if rem(count, 2) == 1,
      do: Enum.at(sorted, middle),
      else: (Enum.at(sorted, middle - 1) + Enum.at(sorted, middle)) / 2
  end

  def theil_sen([]), do: {0.0, 0.0}
  def theil_sen([{x, y}]), do: {0.0, y - 0.0 * x}

  def theil_sen(points) when is_list(points) do
    slopes =
      for {left, left_index} <- Enum.with_index(points),
          {right, right_index} <- Enum.with_index(points),
          right_index > left_index,
          elem(right, 0) != elem(left, 0) do
        (elem(right, 1) - elem(left, 1)) / (elem(right, 0) - elem(left, 0))
      end

    slope = median(slopes)
    intercept = points |> Enum.map(fn {x, y} -> y - slope * x end) |> median()
    {slope, intercept}
  end

  defp error_unless(errors, true, _error), do: errors
  defp error_unless(errors, false, error), do: [error | errors]
end
