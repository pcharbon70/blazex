defmodule Mix.Tasks.Bh01.BrowserPackage do
  use Mix.Task

  @shortdoc "Packages the disposable BH-01 browser-host fixture"
  @requirements ["compile"]
  @start_module BlazeX.BH01.BrowserHost.Boot
  @fixture_module BlazeX.BH01.BrowserHost

  @impl Mix.Task
  def run(args) do
    {options, []} = OptionParser.parse!(args, strict: [out_dir: :string], aliases: [o: :out_dir])
    out_dir = Keyword.fetch!(options, :out_dir)
    File.mkdir_p!(out_dir)
    boot_beam = create_boot_module(out_dir)
    inputs = bundle_inputs(boot_beam)
    reject_duplicates!(inputs)
    bundle_path = Path.join(out_dir, "bundle.avm")
    File.rm(bundle_path)

    :ok =
      :packbeam_api.create(
        String.to_charlist(bundle_path),
        Enum.map(inputs, &String.to_charlist/1),
        %{start_module: @start_module, include_lines: false}
      )

    File.write!(bundle_path <> ".gz", File.read!(bundle_path) |> :zlib.gzip())
    write_inventory(out_dir, inputs)
    File.rm!(boot_beam)
  end

  defp create_boot_module(out_dir) do
    app = Mix.Project.config() |> Keyword.fetch!(:app)
    specs = gather_app_specs([:kernel, :stdlib, app], %{})
    specs = put_in(specs[:kernel][:env][:shell_history], :disabled)

    contents =
      quote location: :keep do
        @compile autoload: false

        def start do
          specs = unquote(Macro.escape(specs))

          {:ok, _controller} =
            :application_controller.start({:application, :kernel, Map.fetch!(specs, :kernel)})

          for {application, spec} <- specs, application != :kernel do
            :ok = :application.load({:application, application, spec})
          end

          :ok = :application.start_boot(:kernel, :permanent)
          :ok = :application.start_boot(:stdlib, :permanent)
          {:ok, _applications} = :application.ensure_all_started(unquote(app), :permanent)
          unquote(@fixture_module).start()
        end
      end

    environment = %{
      __ENV__
      | file: "/workspace/generated/blazex_bh01_browser_host_boot.ex",
        line: 1
    }

    {:module, @start_module, binary, _} = Module.create(@start_module, contents, environment)
    path = Path.join(out_dir, "Elixir.BlazeX.BH01.BrowserHost.Boot.beam")
    File.write!(path, binary)
    path
  end

  defp bundle_inputs(boot_beam) do
    specs = gather_app_specs([:kernel, :stdlib, Mix.Project.config()[:app]], %{})
    builtin = Popcorn.Build.builtin_apps() |> MapSet.new()

    builtin_beams =
      [:erts, :popcorn_lib | Enum.filter(Map.keys(specs), &MapSet.member?(builtin, &1))]
      |> Enum.uniq()
      |> Enum.flat_map(fn app ->
        Path.wildcard(Path.join(patched_ebin_dir(app), "*.beam"))
      end)

    fixture_beams =
      Mix.Project.compile_path()
      |> Path.join("*.beam")
      |> Path.wildcard()
      |> Enum.reject(&String.contains?(&1, "Elixir.Mix.Tasks.Bh01.BrowserPackage.beam"))

    popcorn_api_beams =
      [Popcorn.Wasm, Popcorn.TrackedObject]
      |> Enum.map(&:code.which/1)
      |> Enum.reject(&(&1 in [:non_existing, :preloaded]))
      |> Enum.map(&List.to_string/1)

    json_beams = :jason |> Application.app_dir("ebin/*.beam") |> Path.wildcard()

    [boot_beam | builtin_beams ++ fixture_beams ++ popcorn_api_beams ++ json_beams]
    |> Enum.uniq_by(&Path.basename/1)
    |> Enum.sort_by(fn path -> {path != boot_beam, Path.basename(path)} end)
  end

  defp reject_duplicates!(paths) do
    duplicates =
      paths
      |> Enum.group_by(&Path.basename/1)
      |> Enum.filter(fn {_name, members} -> length(members) > 1 end)

    if duplicates != [], do: Mix.raise("duplicate bundle modules: #{inspect(duplicates)}")
  end

  # Popcorn.Build embeds the build root used to compile the dependency. The
  # fixture may be moved into an equivalent clean workspace afterwards, so its
  # package task resolves patched runtime applications from the active Mix
  # build path rather than that stale compile-time absolute path.
  defp patched_ebin_dir(app) do
    Path.join([
      Mix.Project.build_path(),
      "lib",
      "popcorn",
      "popcorn_patches",
      to_string(app),
      "ebin"
    ])
  end

  defp write_inventory(out_dir, paths) do
    inventory = %{
      schema_version: "1.0.0",
      mode: "browser-release",
      start_module: inspect(@start_module),
      include_lines: false,
      resources: [],
      modules: Enum.map(paths, &Path.basename(&1, ".beam"))
    }

    File.write!(
      Path.join(out_dir, "module-inventory.json"),
      Jason.encode_to_iodata!(inventory, pretty: true)
    )
  end

  defp gather_app_specs([], specs), do: specs

  defp gather_app_specs(apps, specs) do
    new_apps = Enum.reject(apps, &Map.has_key?(specs, &1))

    new_specs =
      for app <- new_apps, spec = Application.spec(app), spec != nil, into: %{} do
        {app, [env: Application.get_all_env(app) |> Enum.sort()] ++ spec}
      end

    dependencies =
      new_specs |> Enum.flat_map(fn {_app, spec} -> spec[:applications] || [] end) |> Enum.uniq()

    gather_app_specs(dependencies, Map.merge(specs, new_specs))
  end
end
