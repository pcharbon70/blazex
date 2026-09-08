Code.require_file("reconciliation_cases.exs", __DIR__)

defmodule BlazeX.BH04.ConformanceRunner do
  alias BlazeX.BH04.ReconciliationCases, as: Cases
  alias BlazeX.UITree.{Accessibility, IntentSet, Document, Node}
  alias BlazeX.Renderer.{Session, Headless}
  alias BlazeX.Renderer.Headless.Normalizer
  alias BlazeX.Renderer.DOM.{Portable, ReconciledSession, Retained}
  alias BlazeX.Renderer.DOM.Protocol.Codec

  def json(value) when is_tuple(value), do: value |> Tuple.to_list() |> json()
  def json(value) when is_list(value), do: Enum.map(value, &json/1)
  def json(value) when is_atom(value), do: Atom.to_string(value)
  def json(value) when is_integer(value), do: Integer.to_string(value)
  def json(value), do: value

  def accessibility_update do
    intent = Cases.rich(2)

    accessibility =
      Enum.map(intent.accessibility, fn item ->
        {:ok, next} =
          Accessibility.new(item.owner, item.role,
            name: item.name,
            description: "Updated description",
            relationships: item.relationships,
            states: %{invalid: true, required: true, busy: false},
            live: :polite
          )

        next
      end)

    {:ok, result} =
      IntentSet.new(intent.document,
        accessibility: accessibility,
        focus: intent.focus,
        selections: intent.selections,
        layouts: intent.layouts
      )

    result
  end

  def root(%IntentSet{document: document}), do: root(document)
  def root(%Document{root: node}), do: node
  def root(%Node{} = node), do: node

  def identities(node),
    do:
      Map.new(
        [{Normalizer.identity(node.identity), Portable.id(node.identity)}] ++
          Enum.flat_map(node.children, &Map.to_list(identities(&1)))
      )

  def tree({:node, _, kind, identity, _key, text, children}, ids) do
    [
      %{
        "id" => Map.fetch!(ids, identity),
        "kind" => Atom.to_string(kind),
        "text" => if(text == :none, do: nil, else: elem(text, 1)),
        "children" => Enum.map(children, &Map.fetch!(ids, elem(&1, 3)))
      }
    ] ++
      Enum.flat_map(children, &tree(&1, ids))
  end

  def oracle(nil), do: nil

  def oracle(output) do
    {:ok, session} = Session.mount(Headless, output)
    snapshot = session.artifact.value
    ids = identities(root(output))

    role = %{
      text_field: "textbox",
      generic: "generic",
      text: "text",
      group: "group",
      button: "button",
      checkbox: "checkbox",
      list: "list",
      list_item: "listitem",
      dialog: "dialog",
      status: "status"
    }

    relations = %{
      labelled_by: "aria-labelledby",
      described_by: "aria-describedby",
      controls: "aria-controls",
      owns: "aria-owns",
      error_message: "aria-errormessage"
    }

    accessibility =
      Enum.map(snapshot.accessibility, fn
        {:accessibility, _, identity, semantic_role, name, description, states, relationships,
         live} ->
          attrs = %{"role" => Map.fetch!(role, semantic_role)}
          attrs = if name == :none, do: attrs, else: Map.put(attrs, "aria-label", elem(name, 1))

          attrs =
            if description == :none,
              do: attrs,
              else: Map.put(attrs, "aria-description", elem(description, 1))

          attrs =
            Enum.reduce(states, attrs, fn {:state, key, value}, acc ->
              Map.put(acc, "aria-" <> Atom.to_string(key), Atom.to_string(value))
            end)

          attrs =
            Enum.reduce(relationships, attrs, fn {:relationship, key, targets}, acc ->
              Map.put(
                acc,
                Map.fetch!(relations, key),
                Enum.map_join(targets, " ", &Map.fetch!(ids, &1))
              )
            end)

          attrs =
            if live == :off, do: attrs, else: Map.put(attrs, "aria-live", Atom.to_string(live))

          %{"id" => Map.fetch!(ids, identity), "attributes" => Retained.cells(attrs)}
      end)

    %{
      "digest" => snapshot.digest,
      "tree" => tree(snapshot.tree, ids),
      "accessibility" => accessibility,
      "bindings" => json(snapshot.bindings),
      "focus" => json(snapshot.focus),
      "selection" => json(snapshot.selections)
    }
  end

  def rows do
    scenarios =
      Cases.scenarios() ++
        [{"accessibility-state-live-update", Cases.rich(), accessibility_update(), :update}]

    Enum.map(scenarios, fn {name, old, next, _} = scenario ->
      setup =
        if old do
          {:ok, mounted} = ReconciledSession.mount(old)
          ReconciledSession.transaction(mounted)
        end

      result = Cases.execute(scenario)
      observed = oracle(next)

      if next do
        dom = Map.new(result["after"]["nodes"], &{&1["id"], &1})

        Enum.each(observed["tree"], fn semantic ->
          node = Map.fetch!(dom, semantic["id"])
          true = semantic["kind"] == Retained.values(node["attributes"])["data-bx-kind"]
          true = semantic["text"] == node["text"]
          true = semantic["children"] == node["children"]
        end)

        Enum.each(observed["accessibility"], fn item ->
          attrs = Retained.values(dom[item["id"]]["attributes"])

          true =
            Enum.all?(item["attributes"], fn %{"name" => key, "value" => value} ->
              attrs[key] == value
            end)
        end)
      end

      result
      |> Map.put("setup", setup)
      |> Map.put("headless_before", oracle(old))
      |> Map.put("headless_after", observed)
      |> Map.put("scenario_id", "bh04-9-" <> name)
    end)
  end

  def run do
    first = rows()
    true = first == rows()

    bytes =
      Enum.map_join(first, "", fn row ->
        row["scenario_id"] <>
          "|" <>
          Base.encode64(Codec.encode!(row)) <> "|" <> Codec.digest(row) <> "\n"
      end)

    path = Path.expand("../conformance-fixtures-v0.1.0.txt", __DIR__)

    if System.argv() == ["--write"],
      do: File.write!(path, bytes),
      else: true = File.read!(path) == bytes

    IO.puts("Phase 9: #{length(first)} deterministic semantic/headless/standalone scenarios")
  end
end

BlazeX.BH04.ConformanceRunner.run()
