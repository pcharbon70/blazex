Code.require_file("reconciliation_cases.exs", __DIR__)
alias BlazeX.BH04.ReconciliationCases
alias BlazeX.Renderer.DOM.Protocol.Codec
alias BlazeX.Renderer.DOM.ReconciledSession

rows = Enum.map(ReconciliationCases.scenarios(), fn {_, old, _, _} = scenario ->
  setup = if old do
    {:ok, mounted} = ReconciledSession.mount(old)
    ReconciledSession.transaction(mounted)
  else
    nil
  end
  Map.put(ReconciliationCases.execute(scenario), "setup", setup)
end)

bytes = Enum.map_join(rows, "", fn row ->
  row["name"] <> "|" <> Base.encode64(Codec.encode!(row)) <> "|" <> Codec.digest(row) <> "\n"
end)
path = Path.expand("../atomic-dom-fixtures-v0.1.0.txt", __DIR__)
if System.argv() == ["--write"], do: File.write!(path, bytes), else: true = File.read!(path) == bytes
IO.puts("BH-04 Phase 4: #{length(rows)} actual reconciler scenarios with initial setup transactions")
