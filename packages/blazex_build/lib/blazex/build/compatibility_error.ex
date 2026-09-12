defmodule BlazeX.Build.CompatibilityError do
  defexception [:report]

  @impl true
  def message(%{report: report}) do
    details =
      report["violations"]
      |> Enum.map_join(", ", fn row ->
        "#{row["kind"]}:#{row["subject"]}: expected #{row["expected"]}, got #{row["actual"]}"
      end)

    "candidate is incompatible with #{report["profile_id"]}: #{details}"
  end
end
