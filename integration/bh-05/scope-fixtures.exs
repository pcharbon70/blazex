Code.require_file("root-fixtures.exs", __DIR__)

defmodule BlazeX.BH05.ScopeRoot do
  use BlazeX.Component,
    role: :root,
    context: ["locale"],
    schema: [props: [], slots: []]

  def mount(_), do: {:state, 0}
  def update(%{state: {:present, n}}), do: {:state, n + 1}

  def render(%{contexts: %{"locale" => value}}),
    do: {:output, {:semantic, 1, %{kind: :group, accessibility: %{role: :group, name: value}}}}

  def terminate(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.ScopeChild do
  use BlazeX.Component, role: :stateful, context: ["locale"], schema: [props: [], slots: []]
  def init(%{contexts: %{"locale" => value}}), do: {:state, value}
  def update(%{contexts: %{"locale" => value}}), do: {:state, value}

  def render(%{state: {:present, value}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: value}}}

  def dispose(input), do: BlazeX.Component.Input.validate(input)
end

defmodule BlazeX.BH05.ScopePure do
  use BlazeX.Component,
    role: :pure,
    context: ["locale"],
    schema: [
      props: [],
      slots: [
        {"default",
         [boundary: :host, max: 1, key: :required, context: {:record, [{"count", :integer}]}]}
      ]
    ]

  def render(%{
        contexts: %{"locale" => value},
        slots: %{"default" => [%{context: %{"count" => count}}]}
      }),
      do:
        {:output,
         {:semantic, 1,
          %{
            kind: :group,
            accessibility: %{role: :group, name: value <> ":" <> Integer.to_string(count)}
          }}}
end

defmodule BlazeX.BH05.ScopeFixtures do
  alias BlazeX.BH05.{ScopeRoot, ScopeChild, ScopePure, RootRendererPort}
  alias BlazeX.Component.{ComponentRegistry, Contract, Schema}
  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Accessibility, Document, IntentSet, Node, ScopedEvaluator}
  def owner(root \\ "scope", generation \\ 1), do: %{root: root, path: [], generation: generation}
  def provider(value, owner \\ owner()), do: %{name: "locale", owner: owner, value: value}

  def spec(root \\ "scope"),
    do: %{
      root: root,
      instance: root <> "-instance",
      owner: "runtime",
      component: ScopeRoot,
      public_id: "root",
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 5000
    }

  def entry(id, module) do
    m = module.__blazex_component__()

    %{
      id: id,
      module: module,
      role: m.role,
      contract_version: Contract.version(),
      schema_version: Schema.version(),
      runtimes: [:erts],
      capabilities: [],
      contexts: ["locale"],
      actions: [],
      package: "fixtures",
      visibility: :public,
      feature_bundle: nil
    }
  end

  def registry(root) do
    {:ok, r} =
      ComponentRegistry.new(
        [
          [entry("child", ScopeChild), entry("alternate", ScopeChild)],
          [entry("pure", ScopePure)]
        ],
        %{
          root: root,
          generation: 1,
          runtime: :erts,
          capabilities: [],
          contexts: ["locale"],
          actions: []
        }
      )

    r
  end

  def config(root \\ "scope", mode \\ :tracked) do
    template = %{
      module: ScopeRoot,
      public_id: "root",
      site: "fixture",
      key: "root",
      props: %{},
      slots: %{},
      children: ["child", "pure"]
    }

    graph = %{
      "root" => template,
      "child" => %{template | module: ScopeChild, public_id: "child", key: "child", children: []},
      "pure" => %{
        template
        | module: ScopePure,
          public_id: "pure",
          key: "pure",
          children: [],
          slots: %{
            "default" => [
              %{
                "key" => "s",
                "context" => %{"count" => 7},
                "content" => %{"kind" => "text", "value" => "slot"}
              }
            ]
          }
      }
    }

    owners =
      Map.new(
        ["root", "child", "alternate", "pure"],
        &{&1, %{provide: ["locale"], consume: ["locale"]}}
      )

    %{
      reference: "root",
      graph: graph,
      scope: %{
        boundary: :host,
        providers: [provider("old", owner(root))],
        manifest: %{
          definitions: %{
            "locale" => %{
              version: 1,
              schema: :string,
              boundary: :host,
              mode: mode,
              default: {:present, "default"},
              doc: "Public locale",
              visibility: :public,
              advisory: false
            }
          },
          owners: owners
        },
        registry: registry(root),
        calls: %{
          "child" => %{
            initial: "child",
            allowed: ["child", "alternate"],
            role: :stateful,
            schema_version: Schema.version(),
            fallback: "child"
          },
          "pure" => %{
            initial: "pure",
            allowed: ["pure"],
            role: :pure,
            schema_version: Schema.version(),
            fallback: nil
          }
        }
      }
    }
  end

  def policy,
    do: %{
      producers: %{
        "ui" => %{
          component: "root",
          classes: [:event, :message],
          routes: [:self],
          supersedable: []
        }
      },
      events: %{increment: :integer},
      messages: %{},
      components: %{"root" => [:self]}
    }

  def ports(config, renderer),
    do: %{
      evaluator: {ScopedEvaluator, config},
      renderer: {RootRendererPort, renderer},
      host: {RootRendererPort, renderer}
    }

  def oracle(value, root \\ "scope", generation \\ 1, child_id \\ "child") do
    {:ok, id} = Identity.new(root, generation)

    {:ok, child_identity} = Identity.child(id, {child_id, "fixture", :child, "child"})
    {:ok, child} = Node.text(child_identity, value)
    {:ok, pure_identity} = Identity.child(id, {"pure", "fixture", :child, "pure"})
    {:ok, slot_identity} = Identity.child(pure_identity, {:slot, "default", "s"})
    {:ok, slot} = Node.text(slot_identity, "slot")
    {:ok, pure} = Node.container(:group, pure_identity, [slot])
    {:ok, group} = Node.container(:group, id, [child, pure])
    {:ok, doc} = Document.new(group, [])
    {:ok, a11y} = Accessibility.new(id, :group, name: value)
    {:ok, pure_a11y} = Accessibility.new(pure_identity, :group, name: value <> ":7")
    {:ok, output} = IntentSet.new(doc, accessibility: [a11y, pure_a11y])
    output
  end
end
