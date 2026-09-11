Code.require_file("../../bh-05/recovery-fixtures.exs", __DIR__)

defmodule BlazeX.Conformance.RecoveryTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH05.{RecoveryFixtures, RecoveryProvider, RecoveryRenderer}
  alias BlazeX.Component.{Action, Input, LocalView, NestedTable, RecoveryView, ScheduledView}
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Accessibility, Binding, Document, Focus, IntentSet, Node}

  setup do
    %{supervisor: start_supervised!(LocalView.Supervisor)}
  end

  defp start(context, root, fault \\ "none", options \\ []) do
    state =
      start_supervised!({Agent, fn -> %{accepted: nil, pending: nil} end}, id: {root, :renderer})

    resources = start_supervised!({Agent, fn -> %{} end}, id: {root, :resources})

    config = %{
      state: state,
      resources: resources,
      observer: self(),
      mode: Keyword.get(options, :mode, :ok),
      child_fault: Keyword.get(options, :child, "none")
    }

    policy = %{RecoveryFixtures.policy() | automatic: Keyword.get(options, :automatic, false)}
    spec = RecoveryFixtures.spec(root, fault)

    {:ok, handle} =
      RecoveryView.start(
        context.supervisor,
        spec,
        RecoveryFixtures.ports(config),
        RecoveryFixtures.schedule(),
        policy,
        RecoveryFixtures.actions(config)
      )

    Map.merge(context, %{root: root, handle: handle, config: config, spec: spec})
  end

  defp commit(c, correlation) do
    :ok = RecoveryRenderer.commit(c.config, correlation)

    :ok =
      LocalView.acknowledge(c.supervisor, c.handle, %{
        correlation: correlation,
        result: :committed
      })
  end

  defp mounted(c) do
    assert_receive {:recovery_submission, mount, _}, 1000
    assert mount.operation == :mount
    commit(c, mount)
    c
  end

  defp snapshot(c) do
    {:ok, value} = LocalView.inspect_root(c.supervisor, c.handle)
    assert Input.portable?(value)
    value
  end

  defp oracle(root, generation) do
    {:ok, id} = Identity.new(root, generation)
    {:ok, status_id} = Identity.child(id, "failure-status")
    {:ok, status_text} = Node.text(status_id, "This component is unavailable.")
    {:ok, retry_id} = Identity.child(id, "retry")
    {:ok, label_id} = Identity.child(retry_id, "label")
    {:ok, label} = Node.text(label_id, "Try again")
    {:ok, button} = Node.container(:action, retry_id, [label])
    {:ok, group} = Node.container(:group, id, [status_text, button])
    {:ok, binding} = Binding.new(:activate, id, retry_id)
    {:ok, doc} = Document.new(group, [binding])

    {:ok, status} =
      Accessibility.new(id, :status, name: "Component unavailable", live: :assertive)

    {:ok, action} = Accessibility.new(retry_id, :button, name: "Try again")
    {:ok, focus} = Focus.new(retry_id, :target, order: 0, auto_focus: true)
    {:ok, output} = IntentSet.new(doc, accessibility: [status, action], focus: [focus])
    output
  end

  defp failure(c) do
    assert_receive {:recovery_submission, correlation, candidate}, 1000
    assert correlation.operation == :failure
    assert candidate.token.output == oracle(c.root, correlation.generation)
    refute inspect(candidate.state.failure) =~ "private"
    commit(c, correlation)
    s = snapshot(c)
    assert s.status == :failed and s.recovery.failure.fallback == :committed
    assert s.recovery.cleanup.unresolved == 0 and s.recovery.cleanup.elapsed_ms < 1000
    {candidate.state.failure, s}
  end

  test "BX-ACC-FAILURE-BX-FAIL-COMPONENT callback matrix contains failures and preserves healthy sibling",
       context do
    sibling = start(context, "healthy-sibling") |> mounted()
    before = snapshot(sibling).accepted
    startup = ["mount_raise", "mount_reject", "mount_result", "mount_state", "render", "semantic"]

    cases =
      Enum.map(startup, &{:startup, &1}) ++
        [{:child, "init"}, {:child, "render"}] ++
        for(
          kind <- [:event, :message],
          fault <- ["raise", "reject", "result", "state"],
          do: {kind, fault}
        ) ++ [{:update, "update"}]

    trace =
      for {{kind, fault}, n} <- Enum.with_index(cases, 1) do
        c =
          start(context, "fault-#{n}", if(kind == :startup, do: fault, else: "none"),
            child: if(kind == :child, do: fault, else: "none")
          )

        if kind not in [:startup, :child] do
          mounted(c)
          envelope = RecoveryFixtures.envelope(c.root, 1, kind, fault)

          envelope =
            if kind == :update,
              do: %{
                envelope
                | name: "props",
                  payload: %{props: %{"fault" => "update"}, slots: %{}}
              },
              else: envelope

          assert {:ok, _} = ScheduledView.enqueue(c.supervisor, c.handle, envelope)
        end

        {f, _} = failure(c)
        assert snapshot(sibling).accepted == before
        assert :ok = LocalView.stop(c.supervisor, c.handle)
        %{case: {kind, fault}, code: f.code, stage: f.stage, generation: f.correlation.generation}
      end

    assert :ok = LocalView.stop(sibling.supervisor, sibling.handle)
    IO.puts("RECOVERY_FAILURE_CASES " <> Integer.to_string(length(trace)))
    IO.puts("RECOVERY_FAILURE_SHA256 " <> NestedTable.digest(trace))
  end

  test "effect result failure releases acquired resources including forced timeout cleanup without replay",
       context do
    samples =
      for mode <- [:ok, :slow] do
        c = start(context, "effect-#{mode}", "none", mode: mode) |> mounted()

        {:ok, _} =
          ScheduledView.enqueue(
            c.supervisor,
            c.handle,
            RecoveryFixtures.envelope(c.root, 1, :event, "effect")
          )

        assert_receive {:recovery_submission, event, _}, 1000
        refute_receive {:recovery_request, _}, 10
        commit(c, event)
        assert_receive {:recovery_request, packet}, 1000
        RecoveryProvider.complete(c.config, packet, ["lease-one"])

        {:ok, result} =
          Action.result(packet.correlation, :completed, %{"value" => 1}, ["lease-one"])

        assert :ok = LocalView.action_result(c.supervisor, c.handle, result)
        {f, s} = failure(c)
        assert f.stage == :action_result
        assert Agent.get(c.config.resources, & &1) == %{}
        assert s.actions.pending == 0 and s.actions.leases == 0

        if mode == :slow,
          do: assert(s.recovery.cleanup.forced == 2 and s.recovery.cleanup.timed_out == 2)

        assert {:ok, %{generation: 2}} =
                 RecoveryView.retry(c.supervisor, c.handle, 1, f.fingerprint, :host, c.spec)

        assert_receive {:recovery_submission, fresh, _}, 1000
        assert fresh.generation == 2
        commit(c, fresh)
        assert {:error, _} = LocalView.action_result(c.supervisor, c.handle, result)
        refute_receive {:recovery_request, _}, 20
        assert :ok = LocalView.stop(c.supervisor, c.handle)

        {s.recovery.cleanup.elapsed_ms,
         Enum.map(
           List.flatten(s.recovery.cleanup.pages),
           &Map.take(&1, [:owner, :kind, :status, :force_status, :unresolved])
         )}
      end

    IO.puts(
      "RECOVERY_CLEANUP_MS " <> Enum.map_join(samples, ",", &Integer.to_string(elem(&1, 0)))
    )

    IO.puts("RECOVERY_CLEANUP_SHA256 " <> NestedTable.digest(Enum.map(samples, &elem(&1, 1))))
  end

  test "persistent failure admits three automatic restarts then terminal fallback", context do
    c = start(context, "persistent", "mount_raise", automatic: true)

    for generation <- 1..4 do
      {f, _} = failure(c)
      assert f.correlation.generation == generation
    end

    Process.sleep(150)
    s = snapshot(c)
    assert s.recovery.restart.maximum == 3 and s.recovery.restart.terminal == :restart_intensity
    attempts = s.recovery.restart.attempts
    assert Enum.map(attempts, & &1.automatic_in_window) == [1, 2, 3, 3]
    assert List.last(attempts).monotonic_ms - hd(attempts).monotonic_ms < 5000

    IO.puts(
      "RECOVERY_RETRY_MS " <> Enum.map_join(attempts, ",", &Integer.to_string(&1.monotonic_ms))
    )

    IO.puts(
      "RECOVERY_RESTART_COUNTS 0," <>
        Enum.map_join(attempts, ",", &Integer.to_string(&1.automatic_in_window))
    )

    IO.puts(
      "RECOVERY_RESTART_SHA256 " <>
        NestedTable.digest(Enum.map(attempts, &Map.drop(&1, [:monotonic_ms])))
    )

    assert :ok = LocalView.stop(c.supervisor, c.handle)
  end

  test "BX-ACC-FAILURE-BX-FAIL-RESOURCE-CLEANUP cancels pending work on removal replacement crash and runtime loss",
       context do
    for scenario <- [:removal, :replacement, :crash, :runtime_loss] do
      c = start(context, "cleanup-#{scenario}") |> mounted()

      {:ok, _} =
        ScheduledView.enqueue(
          c.supervisor,
          c.handle,
          RecoveryFixtures.envelope(c.root, 1, :event, "effect")
        )

      assert_receive {:recovery_submission, event, _}, 1000
      commit(c, event)
      assert_receive {:recovery_request, packet}, 1000

      case scenario do
        :removal ->
          assert :ok = LocalView.stop(c.supervisor, c.handle, :removal)

        :replacement ->
          {:ok, replace} = LocalView.replace(c.supervisor, c.handle, 2, c.spec)
          assert_receive {:recovery_submission, ^replace, _}, 1000
          assert replace.generation == 2
          commit(c, replace)

        :crash ->
          guardian =
            Enum.find_value(Supervisor.which_children(c.supervisor), fn {{:blazex_root, root},
                                                                         pid, _, _} ->
              if(root == c.root, do: pid)
            end)

          Process.exit(:sys.get_state(guardian).worker, :kill)
          failure(c)

        :runtime_loss ->
          LocalView.runtime_loss(c.supervisor, c.handle)
          failure(c)
      end

      assert_receive {:recovery_cancel, correlation}, 1000
      assert correlation == packet.correlation
      assert Agent.get(c.config.resources, & &1) == %{}
      {:ok, late} = Action.result(packet.correlation, :completed, %{"value" => 1})
      assert {:error, _} = LocalView.action_result(c.supervisor, c.handle, late)
      assert :ok = LocalView.stop(c.supervisor, c.handle)
      assert_receive {:recovery_renderer_disposed, %{root: root, restore_focus: true}}, 1000
      assert is_binary(root)
    end

    c = start(context, "cleanup-error", "cleanup", child: "dispose") |> mounted()
    assert {:error, :cleanup_failed} = LocalView.stop(c.supervisor, c.handle)
    s = snapshot(c)
    assert s.recovery.cleanup.callback_failures == 2 and s.recovery.cleanup.unresolved == 0
    assert {:error, :cleanup_failed} = LocalView.stop(c.supervisor, c.handle)
    assert snapshot(c) == s
    replacement = start(context, "replace-cleanup-error", "cleanup") |> mounted()
    LocalView.replace(replacement.supervisor, replacement.handle, 1, replacement.spec)
    {fault, _} = failure(replacement)
    assert fault.code == :cleanup_failed
    assert fault.cleanup_errors.callback_failures == 1
    assert snapshot(replacement).status == :failed
    assert :ok = LocalView.stop(replacement.supervisor, replacement.handle)
    IO.puts("RECOVERY_CLEANUP_CASES removal,replacement,crash,runtime_loss,callback_error")
  end
end
