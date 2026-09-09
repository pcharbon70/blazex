[pinned] = System.argv()

for path <- [
      "lib/treeshake/utils/beam_reader.ex",
      "lib/treeshake/utils/beam_analyzer.ex",
      "lib/popcorn/core_erlang_utils.ex"
    ] do
  Code.require_file(Path.join(pinned, path))
end

out = Path.join(pinned, "beams")
File.mkdir!(out)

{:ok, _, []} =
  Kernel.ParallelCompiler.compile_to_path(Path.wildcard("packages/blazex_core/lib/**/*.ex"), out,
    warnings_as_errors: true
  )

fixtures = Code.compile_file("integration/bh-05/schema-fixtures.exs")

for {module, binary} <- fixtures,
    do: File.write!(Path.join(out, Atom.to_string(module) <> ".beam"), binary)

before = BlazeX.BH05.SchemaData.normalize()

runtime = [
  BlazeX.Component.Schema,
  BlazeX.Component.Props,
  BlazeX.Component.Slots,
  BlazeX.Component.Invocation
]

for module <- runtime ++ Enum.map(fixtures, &elem(&1, 0)) do
  {^module, core} =
    Treeshake.Utils.BeamReader.read_core!(Path.join(out, Atom.to_string(module) <> ".beam"))

  %{module: ^module, functions: functions} = Treeshake.Utils.BeamAnalyzer.analyze(module, core)
  binary = Popcorn.CoreErlangUtils.serialize(core)
  {:ok, {^module, [{:imports, imports}]}} = :beam_lib.chunks(binary, [:imports])

  if Enum.any?(imports, fn {m, _, _} ->
       m in [Code, Module, Regex, Phoenix.LiveView, Process, GenServer, BlazeX.Core.Authoring]
     end),
     do: raise("forbidden runtime dependency")

  :code.purge(module)
  {:module, ^module} = :code.load_binary(module, ~c"schema-subset", binary)

  IO.puts(
    "SCHEMA_SUBSET " <>
      inspect(module) <>
      " functions=" <>
      Integer.to_string(length(functions)) <> " imports=" <> inspect(imports, limit: :infinity)
  )
end

after_value = BlazeX.BH05.SchemaData.normalize()
if before != after_value, do: raise("compiler roundtrip normalization drift")
{:ok, value} = after_value

IO.puts(
  "NORMALIZED_SCHEMA_FIXTURE_SHA256 " <>
    (:crypto.hash(:sha256, :erlang.term_to_binary(value, [:deterministic]))
     |> Base.encode16(case: :lower))
)

IO.puts(
  "PASS: 7 modules analyzed/recompiled; identical normalized fixture under ERTS before/after pinned Popcorn compiler roundtrip. No AtomVM execution parity."
)
