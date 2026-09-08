alias BlazeX.Renderer.DOM.ProtocolV2, as: Protocol
alias BlazeX.Renderer.DOM.Protocol.Codec

path = Path.expand("../reconciliation-protocol-fixtures-v0.1.0.txt", __DIR__)

results =
  for line <- File.stream!(path, [], :line) do
    [name, expected, context64, record64] = line |> String.trim() |> String.split("|")
    {:ok, context} = context64 |> Base.decode64!() |> Codec.decode()

    result =
      with {:ok, record} <- record64 |> Base.decode64!() |> Codec.decode(),
           {:ok, value} <- Protocol.new(record, context),
           do: {:ok, Protocol.to_wire(value)}

    {actual, canonical, hash} =
      case result do
        {:ok, value} -> {"ok", Base.encode64(Codec.encode!(value)), Codec.digest(value)}
        {:error, code} -> {code, "", ""}
      end

    if actual != expected, do: raise("fixture mismatch #{name}: #{actual} != #{expected}")
    Enum.join([name, actual, canonical, hash], "|")
  end

report = Enum.join(results, "\n") <> "\n"

case System.argv() do
  [output] -> File.write!(output, report)
  [] -> IO.write(report)
end
