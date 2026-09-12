defmodule BlazeX.Build.SecretAuditError do
  defexception [:report]
  @impl true
  def message(%{report: report}) do
    subjects = report["findings"] |> Enum.map(& &1["subject"]) |> Enum.uniq() |> Enum.sort()

    "candidate secret audit rejected #{length(report["findings"])} redacted finding(s) in #{Enum.join(subjects, ", ")}"
  end
end
