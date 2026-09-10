Code.require_file("action-fixtures.exs", __DIR__)

defmodule BlazeX.BH05.RecoveryRoot do
  use BlazeX.Component,
    role: :root,
    capabilities: ["ui.storage"],
    schema: [props: [{"fault", [type: :string, default: "none"]}], slots: []]

  def mount(%{props: %{"fault" => "mount_raise"}}), do: :erlang.error(:private_secret)
  def mount(%{props: %{"fault" => "mount_reject"}}), do: {:rejected, :failed}
  def mount(%{props: %{"fault" => "mount_result"}}), do: :invalid
  def mount(%{props: %{"fault" => "mount_state"}}), do: {:state, invalid_state(257)}
  def mount(_), do: {:state, 0}
  def update(%{props: %{"fault" => "update"}}), do: :erlang.error(:private_update)
  def update(_), do: :no_change

  def handle_event(%{payload: {:present, %{data: "effect"}}, identity: owner}) do
    {:ok, action} =
      BlazeX.Component.Result.action(:effect_request, "read", 1, owner, %{
        declaration: "read",
        payload: %{"value" => 1},
        timeout_ms: 60000,
        idempotency_key: "recovery-read",
        fallback: :component
      })

    {:actions, 1, [action]}
  end

  def handle_event(%{payload: {:present, %{data: fault}}}), do: event(fault)
  def handle_info(%{payload: {:present, %{data: fault}}}), do: event(fault)
  defp event("raise"), do: :erlang.error(:private_event)
  defp event("reject"), do: {:rejected, :failed}
  defp event("result"), do: :invalid
  defp event("state"), do: {:state, invalid_state(257)}
  defp event(_), do: {:state, 2}
  defp invalid_state(0), do: []
  defp invalid_state(n), do: [0 | invalid_state(n - 1)]
  def effect_result(_), do: :erlang.error(:private_effect_result)
  def render(%{props: %{"fault" => "render"}}), do: :erlang.error(:private_render)
  def render(%{props: %{"fault" => "semantic"}}), do: {:output, {:semantic, 1, %{kind: :unknown}}}

  def render(_),
    do:
      {:output,
       {:semantic, 1,
        %{kind: :group, bindings: [:increment], accessibility: %{role: :group, name: "Healthy"}}}}

  def terminate(%{props: %{"fault" => "cleanup"}}), do: {:rejected, :failed}
  def terminate(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.RecoveryChild do
  use BlazeX.Component,
    role: :stateful,
    schema: [props: [{"fault", [type: :string, default: "none"]}], slots: []]

  def init(%{props: %{"fault" => "init"}}), do: :erlang.error(:private_child)
  def init(_), do: {:state, 0}
  def render(%{props: %{"fault" => "render"}}), do: :erlang.error(:private_child_render)
  def render(_), do: {:output, {:semantic, 1, %{kind: :text, content: "Child"}}}
  def dispose(%{props: %{"fault" => "dispose"}}), do: {:rejected, :failed}
  def dispose(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.RecoveryRenderer do
  alias BlazeX.Renderer.{Headless, Session}

  def submit(config, correlation, candidate) do
    result =
      Agent.get_and_update(config.state, fn state ->
        result =
          cond do
            state.accepted == nil ->
              Session.mount(Headless, candidate.token.output)

            correlation.operation == :update ->
              Session.update(state.accepted, candidate.token.output)

            true ->
              Session.replace(state.accepted, candidate.token.output)
          end

        case result do
          {:ok, rendered} ->
            {:ok,
             %{
               state
               | pending: %{correlation: correlation, before: state.accepted, after: rendered}
             }}

          _ ->
            {{:error, :renderer_rejected}, state}
        end
      end)

    send(config.observer, {:recovery_submission, correlation, candidate})
    result
  end

  def cancel(config, correlation), do: BlazeX.BH05.RootRendererPort.cancel(config, correlation)

  def commit(config, correlation) do
    Agent.get_and_update(config.state, fn state ->
      if state.pending && state.pending.correlation == correlation,
        do: {:ok, %{state | accepted: state.pending.after, pending: nil}},
        else: {{:error, :stale}, state}
    end)
  end

  def dispose(config, request) do
    result =
      Agent.get_and_update(config.state, fn state ->
        if state.accepted, do: {:ok, _} = Session.dispose(state.accepted)
        {:ok, %{state | accepted: nil, pending: nil}}
      end)

    send(config.observer, {:recovery_renderer_disposed, request})
    result
  end

  def force_cleanup(config, %{owner: owner}),
    do:
      dispose(config, %{
        root: owner.root,
        generation: owner.generation,
        restore_focus: true,
        reason: :forced
      })

  def notify(config, record),
    do: send(config.observer, {:recovery_observation, record}) |> then(fn _ -> :ok end)
end

defmodule BlazeX.BH05.RecoveryProvider do
  def select(_, _), do: {:granted, "fixture"}

  def submit(config, packet) do
    Agent.update(config.resources, &Map.put(&1, packet.correlation, :pending))
    send(config.observer, {:recovery_request, packet})
    :accepted
  end

  def complete(config, packet, leases) do
    Agent.update(config.resources, fn resources ->
      Enum.reduce(leases, Map.delete(resources, packet.correlation), &Map.put(&2, &1, :acquired))
    end)
  end

  def cancel(config, packet) do
    Agent.update(config.resources, &Map.delete(&1, packet.correlation))
    send(config.observer, {:recovery_cancel, packet.correlation})
    :ok
  end

  def release(%{mode: :slow}, _), do: Process.sleep(200)

  def release(config, lease) do
    Agent.update(config.resources, &Map.delete(&1, lease.id))
    send(config.observer, {:recovery_release, lease.id})
    :released
  end

  def force_cleanup(config, %{reference: %{id: id}}) do
    Agent.update(config.resources, &Map.delete(&1, id))
    send(config.observer, {:recovery_forced, id})
    :ok
  end

  def force_cleanup(config, %{reference: %{correlation: correlation}}) do
    Agent.update(config.resources, &Map.delete(&1, correlation))
    :ok
  end
end

defmodule BlazeX.BH05.RecoveryFixtures do
  alias BlazeX.BH05.{RecoveryRoot, RecoveryChild, RecoveryRenderer, RecoveryProvider}

  def policy,
    do: %{
      automatic: false,
      user: true,
      host: true,
      changed: true,
      backoff_ms: 100,
      port_timeout_ms: 200
    }

  def spec(root, fault \\ "none"),
    do: %{
      root: root,
      instance: root <> "-instance",
      owner: "runtime",
      component: RecoveryRoot,
      public_id: "root",
      props: %{"fault" => fault},
      slots: %{},
      capabilities: ["ui.storage"],
      fallback: {:static, "recovery"},
      timeout_ms: 5000
    }

  def graph(fault \\ "none") do
    template = %{
      module: RecoveryRoot,
      public_id: "root",
      site: "fixture",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child"]
    }

    %{
      reference: "root",
      graph: %{
        "root" => template,
        "child" => %{
          template
          | module: RecoveryChild,
            public_id: "child",
            key: "child",
            children: [],
            props: %{"fault" => fault}
        }
      }
    }
  end

  def schedule,
    do: %{
      producers: %{
        "root" => %{
          component: "root",
          classes: [:event, :message, :update],
          routes: [:self],
          supersedable: []
        }
      },
      events: %{increment: :string},
      messages: %{"root" => %{"fault" => :string}},
      components: %{"root" => [:self]}
    }

  def ports(config),
    do: %{
      evaluator:
        {BlazeX.UITree.RecoveryEvaluator,
         {{BlazeX.UITree.RootEvaluator, graph(config.child_fault)}, 200}},
      renderer: {RecoveryRenderer, config},
      host: {RecoveryRenderer, config}
    }

  def actions(config),
    do: %{manifest: BlazeX.BH05.ActionFixtures.manifest(), port: {RecoveryProvider, config}}

  def envelope(root, revision, kind, fault) do
    owner = %{root: root, generation: 1, path: []}

    %{
      class: kind,
      producer: "root",
      sequence: 1,
      generation: 1,
      revision: revision,
      source: owner,
      target: owner,
      route: :self,
      name: if(kind == :event, do: :increment, else: "fault"),
      payload: fault,
      supersedable: false,
      timer: :none
    }
  end
end
