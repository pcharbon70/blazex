# Runs under the pinned ERTS image. No callbacks are scheduled or effects run.
{:ok, _, []} =
  Kernel.ParallelCompiler.compile(Path.wildcard("packages/blazex_core/lib/**/*.ex"),
    warnings_as_errors: true
  )

ExUnit.start()

defmodule BlazeX.BH05.CompileCheck do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "documented fixtures compile warning-free and expose only declared callbacks" do
    assert capture_io(:stderr, fn ->
             compiled = Code.compile_file("integration/bh-05/authoring-fixtures.exs")
             assert length(compiled) == 3

             for {module, binary} <- compiled do
               metadata = module.__blazex_component__()

               assert metadata.callbacks ==
                        Enum.sort(Enum.map(metadata.required ++ metadata.optional, &{&1, 1}))

               assert metadata.version == BlazeX.Component.Contract.version()
               assert metadata.visibility == :public_candidate
               {:ok, {^module, [{:exports, exports}]}} = :beam_lib.chunks(binary, [:exports])

               assert Enum.sort(
                        exports --
                          [__info__: 1, module_info: 0, module_info: 1, __blazex_component__: 0]
                      ) == metadata.callbacks

               IO.puts("API " <> inspect(module) <> " " <> inspect(metadata, limit: :infinity))
             end
           end) == ""
  end

  test "forbidden host renderer server and compatibility surfaces reject" do
    for {index, body} <-
          Enum.with_index([
            "alias BlazeX.Core.Evaluator, as: Private; def render(i), do: Private.mount(i,i,i)",
            "import Process, only: [get: 1]; def render(_), do: get(:secret)",
            "def render(i), do: Phoenix.LiveView.assign(i, :x, 1)",
            "def render(i), do: BlazeX.Renderer.DOM.mount(i)",
            "def render(i), do: Popcorn.Wasm.call(i)",
            "def render(i), do: Plug.Conn.send_resp(i, 200, \"body\")",
            "def render(_), do: :erlang.spawn(fn -> :ok end)",
            "def render(_), do: :erlang.send(self(), :message)",
            "def render(_), do: Code.eval_string(\"1\")"
          ])
          |> Enum.map(fn {body, index} -> {index, body} end) do
      assert_raise CompileError, "BH-05 authoring: forbidden_dependency", fn ->
        Code.compile_string(
          "defmodule BlazeX.BH05.Forbidden#{index} do use BlazeX.Component, role: :pure; #{body} end"
        )
      end
    end

    for {index, options} <-
          Enum.with_index([
            "role: :pure, razor: true",
            "role: :root, render_mode: :server",
            "role: :pure, inject: [Foo]",
            "role: :pure, registry: [BlazeX.Core.Evaluator]",
            "role: :pure, context: [self()]",
            "role: :pure, public: false"
          ])
          |> Enum.map(fn {options, index} -> {index, options} end) do
      assert_raise CompileError, "BH-05 authoring: invalid_declaration", fn ->
        Code.compile_string(
          "defmodule BlazeX.BH05.BadOptions#{index} do use BlazeX.Component, #{options}; def render(_), do: :ok end"
        )
      end
    end
  end
end
