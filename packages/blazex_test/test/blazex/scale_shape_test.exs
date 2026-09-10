defmodule BlazeX.ScaleShapeTest do
  use ExUnit.Case, async: true

  alias BlazeX.Test.ScaleShape

  test "freezes cleanup boundary, payload and repetition workloads" do
    contract = ScaleShape.cleanup_contract()

    assert contract.counts == [0, 1, 63, 64, 65, 127, 128, 129, 255, 256, 257, 511, 512]
    assert contract.page_size == 64
    assert contract.maximum_page_size == 128

    erts = ScaleShape.cleanup_workloads(:erts)
    chrome = ScaleShape.cleanup_workloads(:chrome)
    firefox = ScaleShape.cleanup_workloads(:firefox)

    assert count(erts, :canonical, 512) == 100
    assert count(erts, :canonical, 256) == 20
    assert count(chrome, :canonical, 512) == 20
    assert count(chrome, :canonical, 256) == 10
    assert count(firefox, :maximum, 512) == 20
    assert count(firefox, :minimal, 64) == 10
    assert Enum.all?(erts ++ chrome ++ firefox, & &1.retained)
  end

  test "computes nearest-rank statistics and a robust linear model" do
    assert ScaleShape.nearest_rank(Enum.to_list(1..100), 95) == 95
    assert ScaleShape.median([1, 9, 2, 3]) == 2.5
    assert ScaleShape.theil_sen([{64, 64}, {128, 128}, {256, 256}]) == {1.0, 0.0}

    records =
      for count <- [64, 128, 256, 512], sample <- 1..3 do
        %{
          runtime: :firefox,
          payload_class: :canonical,
          count: count,
          sample: sample,
          elapsed_ms: count
        }
      end

    assert [%{alarms: [], model: %{method: :theil_sen, slope: 1.0}}] =
             ScaleShape.analyze(records)
  end

  test "retains and reports a superlinear intermediate scaling cliff" do
    records = [
      row(64, 70),
      row(128, 130),
      row(256, 900),
      row(512, 520)
    ]

    assert [%{alarms: alarms, points: points}] = ScaleShape.analyze(records)
    assert Enum.any?(alarms, &(&1.x == 256 and &1.observed == 900))
    assert Enum.map(points, & &1.x) == [64, 128, 256, 512]
  end

  test "structural validation rejects hidden process, page and message amplification" do
    amplification = %{
      page_size: 64,
      maximum_page_size: 128,
      normal_worker_starts: 1,
      forced_worker_starts: 0,
      total_worker_starts: 1,
      peak_live_cleanup_workers: 1,
      lease_pages_sent: 8,
      protocol_messages: 18,
      normal: %{pages_sent: 9},
      forced: %{pages_sent: 0}
    }

    assert ScaleShape.cleanup_structural_errors(%{count: 512, amplification: amplification}) ==
             []

    hidden = %{
      amplification
      | normal_worker_starts: 512,
        total_worker_starts: 512,
        lease_pages_sent: 1,
        protocol_messages: 513
    }

    assert ScaleShape.cleanup_structural_errors(%{count: 512, amplification: hidden}) == [
             :normal_worker_amplification,
             :total_worker_amplification,
             :lease_page_mismatch,
             :message_amplification
           ]
  end

  defp count(workloads, payload, count),
    do: Enum.count(workloads, &(&1.payload_class == payload and &1.count == count))

  defp row(count, elapsed),
    do: %{
      runtime: :firefox,
      payload_class: :canonical,
      count: count,
      elapsed_ms: elapsed
    }
end
