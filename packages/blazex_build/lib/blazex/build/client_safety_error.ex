defmodule BlazeX.Build.ClientSafetyError do
  @moduledoc false
  defexception [:report]

  @impl Exception
  def message(%{report: report}) do
    details =
      report["violations"]
      |> Enum.map_join("; ", fn row ->
        "#{row["kind"]}:#{row["subject"]}:#{row["classification"]}"
      end)

    "client safety rejected: " <> details
  end
end
