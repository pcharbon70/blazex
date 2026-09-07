Code.require_file("reconciliation_cases.exs", __DIR__)
alias BlazeX.BH04.ReconciliationCases
alias BlazeX.Renderer.DOM.Protocol.Codec

rows = Enum.map(ReconciliationCases.scenarios(), &ReconciliationCases.execute/1)

bytes =
  Enum.map_join(rows, "", fn row ->
    row["name"] <> "|" <> Base.encode64(Codec.encode!(row)) <> "|" <> Codec.digest(row) <> "\n"
  end)

case System.argv() do
  ["--write"] ->
    File.write!(Path.expand("../reconciliation-fixtures-v0.1.0.txt", __DIR__), bytes)

  [] ->
    true = File.read!(Path.expand("../reconciliation-fixtures-v0.1.0.txt", __DIR__)) == bytes

  [destination] ->
    File.write!(destination, bytes)
end

IO.puts(
  "BH-04 Phase 3: #{length(rows)} callback traces, exact full-root projection parity, canonical fixture digest #{Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)}"
)
