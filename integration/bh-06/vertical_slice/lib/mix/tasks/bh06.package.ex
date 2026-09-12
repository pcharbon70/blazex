defmodule Mix.Tasks.Bh06.Package do
  use Mix.Task
  @compile {:no_warn_undefined, [:packbeam_api, Jason]}
  @requirements ["compile"]
  @start_module BlazeX.BH06.VerticalSlice.Boot
  @component_modules [
    BlazeX.BH06.VerticalSlice.Counter,
    BlazeX.BH06.VerticalSlice.Unused
  ]

  def run(args) do
    fixture_build = Path.expand("../../../../../fixtures/browser_host/_build/dev/lib", __DIR__)
    Code.prepend_path(Path.join(fixture_build, "popcorn/ebin"))
    Code.prepend_path(Path.join(fixture_build, "jason/ebin"))
    {options, []} = OptionParser.parse!(args, strict: [out_dir: :string])
    output = Keyword.fetch!(options, :out_dir) |> Path.expand()
    temporary = Path.join(System.tmp_dir!(), "bh06-package-#{System.unique_integer([:positive])}")
    root = Path.expand("../../../../../..", __DIR__)
    File.mkdir_p!(temporary)

    try do
      {inventory, reachability} = reachability_report!()
      policy = client_safety_policy!(root)
      profile = compatibility_profile!(root)
      requirements = compatibility_requirements!(root)
      secret_policy = secret_policy!(root)
      license_policy = license_policy!(root)
      bundle_policy = bundle_policy!(root)
      boot = boot!(temporary)
      inputs = bundle_inputs(boot, fixture_build, reachability)
      secret_inputs = secret_inputs!(root, inputs)
      license_inputs = license_inputs!(secret_inputs)
      bundle_declarations = bundle_declarations!(inputs)

      {safety, compatibility, secret_audit, license_inventory, bundle_plan, archives} =
        BlazeX.Build.ClientClosure.authorize!(
          reachability,
          inventory,
          policy,
          profile,
          requirements,
          secret_policy,
          secret_inputs,
          %{},
          license_policy,
          license_inputs,
          root,
          bundle_policy,
          bundle_declarations,
          fn authorization ->
            package_bundles!(temporary, inputs, authorization["bundle_plan"])
          end
        )

      safety = Map.merge(safety, %{"phase" => 3, "status" => "complete"})
      compatibility = Map.merge(compatibility, %{"phase" => 4, "status" => "complete"})
      secret_audit = Map.merge(secret_audit, %{"phase" => 5, "status" => "complete"})
      license_inventory = Map.merge(license_inventory, %{"phase" => 6, "status" => "complete"})
      bundle_plan = Map.merge(bundle_plan, %{"phase" => 7, "status" => "complete"})

      spec =
        BlazeX.Build.EntryPoint.new!(%{
          id: "counter",
          module: "Elixir.BlazeX.BH06.VerticalSlice.Counter",
          bundle: archives.base,
          runtime_module:
            Path.join(
              root,
              "packages/blazex_runtime_popcorn/runtime/generated/release-web/artifacts/AtomVM.mjs"
            ),
          runtime_wasm:
            Path.join(
              root,
              "packages/blazex_runtime_popcorn/runtime/generated/release-web/artifacts/AtomVM.wasm"
            ),
          host: Path.join(root, "integration/bh-06/vertical_slice/assets/host.js"),
          document: Path.join(root, "integration/bh-06/vertical_slice/assets/index.html"),
          compatibility: %{
            "component" => "blazex.component/0.1-experimental",
            "runtime" => "atomvm-wasm/0.6.6-dev",
            "semantic_tree" => "blazex.ui-tree/1"
          }
        })

      manifest =
        BlazeX.Build.Pipeline.build!(spec, output,
          reachability: reachability,
          client_safety: safety,
          compatibility: compatibility,
          secret_audit: secret_audit,
          license_inventory: license_inventory,
          bundle_plan: bundle_plan,
          feature_bundles: archives.features
        )

      Mix.shell().info("BH-06 Phase 7 package: PASS (#{length(manifest["artifacts"])} assets)")
    after
      File.rm_rf!(temporary)
    end
  end

  defp reachability_report! do
    owned_beams =
      Enum.map(@component_modules, fn module ->
        {Application.app_dir(:blazex_bh06_vertical_slice, "ebin/#{module}.beam"),
         "blazex_bh06_vertical_slice"}
      end)

    entrypoint =
      BlazeX.Build.ClientEntryPoint.new!(%{
        id: "counter",
        module: "BlazeX.BH06.VerticalSlice.Counter"
      })

    inventory = BlazeX.Build.BeamInventory.scan_owned!(owned_beams)

    report =
      BlazeX.Build.Reachability.analyze!([entrypoint], inventory)
      |> Map.merge(%{"phase" => 2, "status" => "complete"})

    {inventory, report}
  end

  defp client_safety_policy!(root) do
    root
    |> Path.join("integration/bh-06/client-safety-policy-v0.1.0.json")
    |> File.read!()
    |> Jason.decode!()
    |> BlazeX.Build.ClientSafetyPolicy.new!()
  end

  defp compatibility_profile!(root) do
    root
    |> Path.join("packages/blazex_runtime_popcorn/compatibility-profile-v0.1.0.json")
    |> File.read!()
    |> Jason.decode!()
    |> BlazeX.Build.CompatibilityProfile.new!()
  end

  defp compatibility_requirements!(root) do
    root
    |> Path.join("integration/bh-06/compatibility-requirements-v0.1.0.json")
    |> File.read!()
    |> Jason.decode!()
    |> BlazeX.Build.CompatibilityRequirements.new!()
  end

  defp secret_policy!(root) do
    root
    |> Path.join("integration/bh-06/secret-policy-v0.1.0.json")
    |> File.read!()
    |> Jason.decode!()
    |> BlazeX.Build.SecretPolicy.new!()
  end

  defp license_policy!(root) do
    root
    |> Path.join("integration/bh-06/license-policy-v0.1.0.json")
    |> File.read!()
    |> Jason.decode!()
    |> BlazeX.Build.LicensePolicy.new!()
  end

  defp bundle_policy!(root) do
    root
    |> Path.join("integration/bh-06/bundle-policy-v0.1.0.json")
    |> File.read!()
    |> Jason.decode!()
    |> BlazeX.Build.BundlePolicy.new!()
  end

  defp bundle_declarations!(inputs) do
    Enum.map(inputs, fn path ->
      module = Path.basename(path, ".beam")

      %{
        "label" => "bundle/#{module}.beam",
        "module" => module,
        "bundle_id" =>
          if(module == "Elixir.BlazeX.BH06.VerticalSlice.Counter", do: "counter", else: "base"),
        "bytes" => File.read!(path)
      }
    end)
  end

  defp license_inputs!(secret_inputs) do
    Enum.map(secret_inputs, fn input ->
      %{
        "label" => input["label"],
        "bytes" => input["bytes"],
        "component_id" => component_id!(input["label"])
      }
    end)
  end

  defp component_id!("browser/" <> _), do: "blazex"
  defp component_id!("runtime/" <> _), do: "atomvm-runtime"
  defp component_id!("bundle/Elixir.BlazeX." <> _), do: "blazex"
  defp component_id!("bundle/Elixir.Mix.Tasks.Bh06." <> _), do: "blazex"
  defp component_id!("bundle/Elixir.Jason.Encoder.Popcorn." <> _), do: "popcorn"
  defp component_id!("bundle/Elixir.Popcorn." <> _), do: "popcorn"
  defp component_id!("bundle/Elixir.Mix.Tasks.Popcorn." <> _), do: "popcorn"
  defp component_id!("bundle/Elixir.Treeshake" <> _), do: "popcorn"
  defp component_id!("bundle/treeshake_helper.beam"), do: "popcorn"
  defp component_id!("bundle/packbeam_api.beam"), do: "popcorn"
  defp component_id!("bundle/Elixir.Jason" <> _), do: "jason"
  defp component_id!("bundle/Elixir.Enumerable.Jason." <> _), do: "jason"
  defp component_id!("bundle/Elixir.AVMPort.beam"), do: "fissionvm-patches"

  defp component_id!("bundle/" <> patch)
       when patch in [
              "atomvm.beam",
              "atomvm_logger_manager.beam",
              "avm_pubsub.beam",
              "console.beam",
              "emscripten.beam",
              "network.beam"
            ],
       do: "fissionvm-patches"

  defp component_id!("bundle/Elixir." <> _), do: "elixir"
  defp component_id!("bundle/elixir" <> _), do: "elixir"
  defp component_id!("bundle/iex.beam"), do: "elixir"
  defp component_id!("bundle/" <> _), do: "erlang-otp"
  defp component_id!(label), do: Mix.raise("unaccounted license inventory input: #{label}")

  defp package_bundles!(temporary, inputs, plan) do
    ownership = Map.new(plan["inputs"], &{&1["label"], &1["bundle_id"]})

    grouped =
      Enum.group_by(inputs, fn path ->
        Map.fetch!(ownership, "bundle/#{Path.basename(path)}")
      end)

    base =
      package_archive!(
        Path.join(temporary, "base.avm"),
        Map.fetch!(grouped, "base"),
        @start_module
      )

    features =
      plan["bundles"]
      |> Enum.filter(&(&1["kind"] == "feature"))
      |> Enum.map(fn bundle ->
        path = Path.join(temporary, "feature-#{bundle["id"]}.avm")
        package_archive!(path, Map.fetch!(grouped, bundle["id"]), nil)
        %{"id" => bundle["id"], "path" => path}
      end)

    %{base: base, features: features}
  end

  defp package_archive!(target, inputs, start_module) do
    duplicates =
      inputs
      |> Enum.group_by(&Path.basename/1)
      |> Enum.filter(fn {_, rows} -> length(rows) > 1 end)

    if duplicates != [], do: Mix.raise("duplicate bundle module names")

    :ok =
      :packbeam_api.create(String.to_charlist(target), Enum.map(inputs, &String.to_charlist/1), %{
        start_module: start_module || :undefined,
        include_lines: false
      })

    target
  end

  defp secret_inputs!(root, inputs) do
    bundle =
      Enum.map(inputs, fn path ->
        %{"label" => "bundle/#{Path.basename(path)}", "bytes" => File.read!(path)}
      end)

    fixed = [
      {"browser/host.js", "integration/bh-06/vertical_slice/assets/host.js"},
      {"browser/index.html", "integration/bh-06/vertical_slice/assets/index.html"},
      {"runtime/AtomVM.mjs",
       "packages/blazex_runtime_popcorn/runtime/generated/release-web/artifacts/AtomVM.mjs"},
      {"runtime/AtomVM.wasm",
       "packages/blazex_runtime_popcorn/runtime/generated/release-web/artifacts/AtomVM.wasm"}
    ]

    bundle ++
      Enum.map(fixed, fn {label, relative} ->
        %{"label" => label, "bytes" => File.read!(Path.join(root, relative))}
      end)
  end

  defp boot!(temporary) do
    specs = specs([:kernel, :stdlib, Mix.Project.config()[:app]], %{})

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
          {:ok, _} = :application.ensure_all_started(:blazex_bh06_vertical_slice, :permanent)
          BlazeX.BH06.VerticalSlice.Browser.start()
        end
      end

    {:module, @start_module, binary, _} =
      Module.create(@start_module, body, %{__ENV__ | file: "/workspace/bh06_boot.ex", line: 1})

    path = Path.join(temporary, "Elixir.BlazeX.BH06.VerticalSlice.Boot.beam")
    File.write!(path, binary)
    path
  end

  defp bundle_inputs(boot, fixture_build, report) do
    unused = MapSet.new(report["unused_modules"])

    app_beams =
      specs([:kernel, :stdlib, Mix.Project.config()[:app]], %{})
      |> Map.keys()
      |> Enum.reject(&(&1 in [:kernel, :stdlib, :elixir, :blazex_build]))
      |> Enum.flat_map(fn app -> Application.app_dir(app, "ebin/*.beam") |> Path.wildcard() end)
      |> Enum.reject(fn path ->
        MapSet.member?(unused, Path.basename(path, ".beam"))
      end)

    popcorn =
      Path.wildcard(Path.join(fixture_build, "popcorn/ebin/*.beam")) ++
        Path.wildcard(Path.join(fixture_build, "jason/ebin/*.beam"))

    patches = Path.wildcard(Path.join(fixture_build, "popcorn/popcorn_patches/*/ebin/*.beam"))

    [boot | patches ++ app_beams ++ popcorn]
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
