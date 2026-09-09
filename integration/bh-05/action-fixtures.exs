Code.require_file("root-fixtures.exs", __DIR__)

defmodule BlazeX.BH05.ActionRoot do
  use BlazeX.Component, role: :root, capabilities: ["ui.storage"], schema: [props: [], slots: []]
  def mount(_), do: {:state, %{value: 0, sequence: 0, leases: [], outcomes: []}}
  def update(_), do: :no_change

  def handle_event(%{
        identity: owner,
        state: {:present, state},
        payload: {:present, %{data: data}}
      }) do
    sequence = Map.fetch!(state, :sequence) + 1

    common = %{
      declaration: "read",
      payload: %{"value" => Map.fetch!(data, "value")},
      timeout_ms: if(Map.fetch!(data, "op") == "timeout", do: 10, else: 60000),
      idempotency_key: "request_" <> Integer.to_string(sequence),
      fallback: :component
    }

    {kind, body} =
      case Map.fetch!(data, "op") do
        "command" ->
          {:command,
           %{
             declaration: "save",
             payload: Map.fetch!(common, :payload),
             timeout_ms: 60000,
             idempotency_key: Map.fetch!(common, :idempotency_key),
             optimistic_revision: 1,
             trust: :untrusted_client
           }}

        "transfer" ->
          {:resource_transfer,
           %{
             lease: hd(Map.fetch!(state, :leases)),
             target: %{
               root: Map.fetch!(owner, :root),
               path: [{"child", "demo", :child, "child"}],
               generation: Map.fetch!(owner, :generation)
             }
           }}

        "release" ->
          {:resource_release, %{lease: hd(Map.fetch!(state, :leases))}}

        _ ->
          {:effect_request, common}
      end

    {:ok, action} =
      BlazeX.Component.Result.action(
        kind,
        "action_" <> Integer.to_string(sequence),
        sequence,
        owner,
        body
      )

    {:actions, %{state | value: Map.fetch!(data, "value"), sequence: sequence}, [action]}
  end

  defp receive_result(%{state: {:present, state}, payload: {:present, result}} = input) do
    :ok = BlazeX.Component.Input.validate(input)

    value =
      if Map.fetch!(result, :status) == :completed,
        do: Map.fetch!(Map.fetch!(result, :value), "value"),
        else: Map.fetch!(state, :value)

    {:state,
     %{
       state
       | value: value,
         leases: Map.fetch!(result, :leases),
         outcomes: Enum.take(Map.fetch!(state, :outcomes) ++ [Map.fetch!(result, :status)], -16)
     }}
  end

  def effect_result(input), do: receive_result(input)

  def render(%{state: {:present, state}}),
    do:
      {:output,
       {:semantic, 1,
        %{
          kind: :group,
          bindings: [:increment],
          accessibility: %{role: :group, name: Integer.to_string(Map.fetch!(state, :value))}
        }}}

  def terminate(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.ActionChild do
  use BlazeX.Component,
    role: :stateful,
    capabilities: ["ui.storage"],
    schema: [props: [], slots: []]

  def init(_), do: {:state, %{value: 0, sequence: 0, leases: [], outcomes: []}}

  def handle_event(%{
        identity: owner,
        state: {:present, state},
        payload: {:present, %{data: data}}
      }) do
    sequence = Map.fetch!(state, :sequence) + 1

    common = %{
      declaration: "read",
      payload: %{"value" => Map.fetch!(data, "value")},
      timeout_ms: if(Map.fetch!(data, "op") == "timeout", do: 10, else: 60000),
      idempotency_key: "request_" <> Integer.to_string(sequence),
      fallback: :component
    }

    {kind, body} =
      case Map.fetch!(data, "op") do
        "command" ->
          {:command,
           %{
             declaration: "save",
             payload: Map.fetch!(common, :payload),
             timeout_ms: 60000,
             idempotency_key: Map.fetch!(common, :idempotency_key),
             optimistic_revision: 1,
             trust: :untrusted_client
           }}

        "transfer" ->
          {:resource_transfer,
           %{
             lease: hd(Map.fetch!(state, :leases)),
             target: %{
               root: Map.fetch!(owner, :root),
               path: [{"child", "demo", :child, "child"}],
               generation: Map.fetch!(owner, :generation)
             }
           }}

        "release" ->
          {:resource_release, %{lease: hd(Map.fetch!(state, :leases))}}

        _ ->
          {:effect_request, common}
      end

    {:ok, action} =
      BlazeX.Component.Result.action(
        kind,
        "action_" <> Integer.to_string(sequence),
        sequence,
        owner,
        body
      )

    {:actions, %{state | value: Map.fetch!(data, "value"), sequence: sequence}, [action]}
  end

  defp receive_result(%{state: {:present, state}, payload: {:present, result}} = input) do
    :ok = BlazeX.Component.Input.validate(input)

    value =
      if Map.fetch!(result, :status) == :completed,
        do: Map.fetch!(Map.fetch!(result, :value), "value"),
        else: Map.fetch!(state, :value)

    {:state,
     %{
       state
       | value: value,
         leases: Map.fetch!(result, :leases),
         outcomes: Enum.take(Map.fetch!(state, :outcomes) ++ [Map.fetch!(result, :status)], -16)
     }}
  end

  def handle_info(input), do: receive_result(input)

  def render(%{state: {:present, state}}),
    do:
      {:output,
       {:semantic, 1,
        %{
          kind: :group,
          bindings: [:increment],
          accessibility: %{role: :group, name: Integer.to_string(Map.fetch!(state, :value))}
        }}}

  def dispose(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.ActionEvaluatorPort do
  alias BlazeX.UITree.RootEvaluator
  def prepare(config, request, prior), do: RootEvaluator.prepare(graph(config), request, prior)

  def prepare_scheduled(config, request, prior),
    do: RootEvaluator.prepare_scheduled(graph(config), request, prior)

  def admit(config, work, prior), do: RootEvaluator.admit(graph(config), work, prior)

  def admit_action(config, action, candidate),
    do: RootEvaluator.admit_action(graph(config), action, candidate)

  def cleanup(config, prior, reason), do: RootEvaluator.cleanup(graph(config), prior, reason)

  def cleanup_removed(config, prior, next),
    do: RootEvaluator.cleanup_removed(graph(config), prior, next)

  defp graph(config), do: Agent.get(config.graph, & &1)
end

defmodule BlazeX.BH05.ActionProvider do
  def submit(config, packet) do
    send(config.observer, {:action_submission, packet})

    cond do
      Map.get(packet, :trust) == :untrusted_client -> :denied
      config.mode == :disconnect -> :disconnected
      true -> :accepted
    end
  end

  def cancel(config, packet) do
    send(config.observer, {:action_cancel, packet})
    :ok
  end

  def release(config, packet) do
    send(config.observer, {:action_release, packet})
    if config.mode == :lost, do: :lost, else: :released
  end
end

defmodule BlazeX.BH05.ActionFixtures do
  alias BlazeX.BH05.{
    ActionRoot,
    ActionChild,
    ActionEvaluatorPort,
    ActionProvider,
    RootRendererPort
  }

  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Accessibility, Binding, Document, IntentSet, Node}

  def spec(root),
    do: %{
      root: root,
      instance: root <> "-instance",
      owner: "runtime",
      component: ActionRoot,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: ["ui.storage"],
      fallback: :none,
      timeout_ms: 5000
    }

  def graph do
    entry = %{
      module: ActionRoot,
      public_id: "root",
      site: "demo",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child"]
    }

    %{
      reference: "root",
      graph: %{
        "root" => entry,
        "child" => %{entry | module: ActionChild, public_id: "child", key: "child", children: []}
      }
    }
  end

  def manifest do
    declaration = %{
      schema_version: "1.0.0",
      request: {:record, [{"value", :integer}]},
      result: {:record, [{"value", :integer}]},
      error: {:record, [{"code", :string}]}
    }

    %{
      effects: %{
        "read" =>
          Map.merge(declaration, %{
            capability: "ui.storage",
            operation: "get",
            fallback: :component,
            lease_kind: "subscription",
            lease_limit: 16
          })
      },
      commands: %{"save" => declaration},
      owners: %{
        "root" => %{effects: ["read"], commands: ["save"], transfers: [:child]},
        "child" => %{effects: ["read"], commands: ["save"], transfers: [:parent]}
      }
    }
  end

  def policy do
    %{
      producers:
        Map.new(
          ["root", "child"],
          &{&1, %{component: &1, classes: [:event, :update], routes: [:self], supersedable: []}}
        ),
      events: %{increment: {:record, [{"op", :string}, {"value", :integer}]}},
      messages: %{},
      components: %{"root" => [:self], "child" => [:self]}
    }
  end

  def ports(config),
    do: %{
      evaluator: {ActionEvaluatorPort, config},
      renderer: {RootRendererPort, config},
      host: {RootRendererPort, config}
    }

  def provider(config) do
    {BlazeX.Effects.ActionBridge,
     %{
       grants: if(config.mode in [:deny, :fallback], do: [], else: [:"ui.storage"]),
       bindings: %{
         "read" => %{
           primary: "provider",
           fallback: if(config.mode == :deny, do: nil, else: "provider")
         }
       },
       commands: %{"save" => "provider"},
       providers: %{"provider" => {ActionProvider, config}}
     }}
  end

  def owner(root), do: %{root: root, path: [], generation: 1}
  def child(root), do: %{root: root, path: [{"child", "demo", :child, "child"}], generation: 1}

  def envelope(root, sequence, revision, op, value, who \\ "root") do
    owner = if who == "root", do: owner(root), else: child(root)

    %{
      class: :event,
      producer: who,
      sequence: sequence,
      generation: 1,
      revision: revision,
      source: owner,
      target: owner,
      route: :self,
      name: :increment,
      payload: %{"op" => op, "value" => value},
      supersedable: false,
      timer: :none
    }
  end

  def oracle(root, value, child_value \\ 0) do
    {:ok, id} = Identity.new(root, 1)
    {:ok, child_id} = Identity.child(id, {"child", "demo", :child, "child"})
    {:ok, child} = Node.container(:group, child_id, [])
    {:ok, group} = Node.container(:group, id, [child])

    bindings =
      Enum.map([id, child_id], fn owner ->
        {:ok, binding} = Binding.new(:increment, id, owner)
        binding
      end)

    {:ok, document} = Document.new(group, bindings)

    accessibility =
      Enum.map([{id, value}, {child_id, child_value}], fn {owner, n} ->
        {:ok, intent} = Accessibility.new(owner, :group, name: Integer.to_string(n))
        intent
      end)

    {:ok, output} = IntentSet.new(document, accessibility: accessibility)
    output
  end
end
