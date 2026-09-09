# Source inputs are extracted from the SHA-256-pinned Popcorn Hex tar by the runner.
[pinned] = System.argv()
Code.require_file(Path.join(pinned, "lib/treeshake/utils/beam_reader.ex"))
Code.require_file(Path.join(pinned, "lib/treeshake/utils/beam_analyzer.ex"))
Code.require_file(Path.join(pinned, "lib/popcorn/core_erlang_utils.ex"))

files = Path.wildcard("packages/blazex_core/lib/**/*.ex")
out = Path.join(pinned, "beams")
File.mkdir!(out)

{:ok, compiled, []} =
  Kernel.ParallelCompiler.compile_to_path(files, out, warnings_as_errors: true)

fixtures = Code.compile_file("integration/bh-05/authoring-fixtures.exs")

runtime = [
  BlazeX.Component.Contract,
  BlazeX.Component.Input,
  BlazeX.Component.Result,
  BlazeX.Component.Pure,
  BlazeX.Component.Stateful,
  BlazeX.Component.Root,
  BlazeX.Core.Identity,
  BlazeX.Core.Portable
]

for module <- runtime do
  unless module in compiled, do: raise("missing runtime module")
end

# Read debug info from the freshly compiled source, never a cached package beam.
for {module, binary} <- fixtures,
    do: File.write!(Path.join(out, Atom.to_string(module) <> ".beam"), binary)

for module <- runtime ++ Enum.map(fixtures, &elem(&1, 0)) do
  path = Path.join(out, Atom.to_string(module) <> ".beam")
  {^module, core} = Treeshake.Utils.BeamReader.read_core!(path)
  %{module: ^module, functions: functions} = Treeshake.Utils.BeamAnalyzer.analyze(module, core)
  true = functions != []
  rebuilt = Popcorn.CoreErlangUtils.serialize(core)
  {:ok, {^module, [{:imports, imports}]}} = :beam_lib.chunks(rebuilt, [:imports])
  forbidden = [BlazeX.Core.Authoring, Code, Module, Regex, Phoenix.LiveView, Process, GenServer]

  if Enum.any?(imports, fn {m, _, _} -> m in forbidden end),
    do: raise("build/host API in runtime subset")

  IO.puts(
    "SUBSET " <>
      inspect(module) <>
      " functions=" <>
      Integer.to_string(length(functions)) <> " imports=" <> inspect(imports, limit: :infinity)
  )
end

IO.puts(
  "PASS: 11 runtime/fixture modules parsed, analyzed and recompiled by pinned Popcorn 0.3.3 tooling on OTP 26.0.2 / Elixir 1.17.3. No AtomVM execution or parity claim."
)
