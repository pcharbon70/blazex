defmodule Mix.Tasks.Bh05.BrowserPackage do
  use Mix.Task
  @compile {:no_warn_undefined, Jason}
  @compile {:no_warn_undefined, :packbeam_api}
  @requirements ["compile"]
  @start_module BlazeX.BH05.Conformance.Boot

  def run(args) do
    fixture_build = Path.expand("../../../../../fixtures/browser_host/_build/dev/lib", __DIR__)
    Code.prepend_path(Path.join(fixture_build, "popcorn/ebin"))
    Code.prepend_path(Path.join(fixture_build, "jason/ebin"))
    {options, []} = OptionParser.parse!(args, strict: [out_dir: :string])
    output = Keyword.fetch!(options, :out_dir)
    File.mkdir_p!(output)
    boot = boot(output)
    inputs = inputs(boot)

    duplicates =
      inputs
      |> Enum.group_by(&Path.basename/1)
      |> Enum.filter(fn {_, rows} -> length(rows) > 1 end)

    if duplicates != [], do: Mix.raise("duplicate bundle modules")
    target = Path.join(output, "bundle.avm")
    File.rm(target)

    :ok =
      :packbeam_api.create(String.to_charlist(target), Enum.map(inputs, &String.to_charlist/1), %{
        start_module: @start_module,
        include_lines: false
      })

    File.write!(target <> ".gz", File.read!(target) |> :zlib.gzip())
    File.rm!(boot)

    File.write!(
      Path.join(output, "module-inventory.json"),
      Jason.encode_to_iodata!(
        %{
          schema_version: "1.0.0",
          start_module: inspect(@start_module),
          modules: Enum.map(inputs, &Path.basename(&1, ".beam"))
        },
        pretty: true
      )
    )
  end

  defp boot(output) do
    specs =
      specs([:kernel, :stdlib, Mix.Project.config()[:app]], %{})
      |> put_in([:kernel, :env, :shell_history], :disabled)

    body =
      quote do
        @compile autoload: false
        def start do
          specs = unquote(Macro.escape(specs))

          {:ok, _} =
            :application_controller.start({:application, :kernel, Map.fetch!(specs, :kernel)})

          for {app, spec} <- specs,
              app != :kernel,
              do: :ok = :application.load({:application, app, spec})

          :ok = :application.start_boot(:kernel, :permanent)
          :ok = :application.start_boot(:stdlib, :permanent)
          {:ok, _} = :application.ensure_all_started(:blazex_bh05_browser_conformance, :permanent)
          BlazeX.BH05.Conformance.Browser.start()
        end
      end

    {:module, @start_module, binary, _} =
      Module.create(@start_module, body, %{__ENV__ | file: "/workspace/bh05_boot.ex", line: 1})

    path = Path.join(output, "Elixir.BlazeX.BH05.Conformance.Boot.beam")
    File.write!(path, binary)
    path
  end

  defp inputs(boot) do
    specs = specs([:kernel, :stdlib, Mix.Project.config()[:app]], %{})
    fixture = Path.expand("../../../../../fixtures/browser_host/_build/dev/lib", __DIR__)
    builtin_beams = Path.wildcard(Path.join(fixture, "popcorn/popcorn_patches/*/ebin/*.beam"))

    app_beams =
      specs
      |> Map.keys()
      |> Enum.reject(&(&1 in [:kernel, :stdlib, :elixir, :logger]))
      |> Enum.flat_map(fn app -> Application.app_dir(app, "ebin/*.beam") |> Path.wildcard() end)

    popcorn =
      Path.wildcard(Path.join(fixture, "popcorn/ebin/*.beam")) ++
        Path.wildcard(Path.join(fixture, "jason/ebin/*.beam"))

    [boot | builtin_beams ++ app_beams ++ popcorn]
    |> Enum.uniq_by(&Path.basename/1)
    |> Enum.sort_by(&{&1 != boot, Path.basename(&1)})
  end

  defp specs([], found), do: found

  defp specs(apps, found) do
    new = Enum.reject(apps, &Map.has_key?(found, &1))

    added =
      for app <- new,
          spec = Application.spec(app),
          spec != nil,
          into: %{},
          do: {app, [env: Application.get_all_env(app) |> Enum.sort()] ++ spec}

    specs(
      added |> Enum.flat_map(fn {_, spec} -> spec[:applications] || [] end) |> Enum.uniq(),
      Map.merge(found, added)
    )
  end
end
