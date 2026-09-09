defmodule BlazeX.BH05.PureControl do
  use BlazeX.Component,
    role: :pure,
    schema: [
      props: [
        {"kind",
         [
           type:
             {:enum, ["surface", "group", "action", "field", "collection", "selection", "text"]},
           required: true
         ]}
      ],
      slots: []
    ]

  def render(%{props: %{"kind" => kind}}) do
    output =
      case kind do
        "surface" ->
          %{
            kind: :surface,
            layout: %{mode: :stack},
            focus: %{behavior: :scope, restore: :previous}
          }

        "group" ->
          %{kind: :group, layout: %{mode: :stack, direction: :row, gap: {:units, 4}}}

        "action" ->
          %{
            kind: :action,
            bindings: [:activate],
            accessibility: %{role: :button, name: "Save"},
            focus: %{behavior: :target, order: 0}
          }

        "field" ->
          %{
            kind: :field,
            bindings: [:change],
            accessibility: %{role: :text_field, name: "Name"},
            focus: %{behavior: :target, order: 1, auto_focus: true},
            selection: %{kind: :text_range, value: %{anchor: 0, focus: 0, direction: :forward}}
          }

        "collection" ->
          %{
            kind: :collection,
            accessibility: %{role: :list},
            selection: %{kind: :multiple, value: ["one"]}
          }

        "selection" ->
          %{kind: :selection, accessibility: %{role: :list_item, states: %{selected: true}}}

        "text" ->
          %{kind: :text, content: "One"}
      end

    {:output, {:semantic, 1, output}}
  end
end

defmodule BlazeX.BH05.ContextShell do
  use BlazeX.Component,
    role: :pure,
    schema: [
      props: [{"title", [type: :string, required: true]}],
      slots: [
        {"default", [required: true, max: 2, context: {:record, [{"count", :integer}]}]},
        {"footer", [required: true, context: {:record, [{"count", :integer}]}]}
      ]
    ]

  def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
end

defmodule BlazeX.BH05.ContextText do
  use BlazeX.Component,
    role: :pure,
    schema: [
      props: [
        {"title", [type: :string, required: true]},
        {"context", [type: {:record, [{"count", :integer}]}, required: true]}
      ],
      slots: []
    ]

  def render(%{props: %{"title" => title, "context" => %{"count" => count}}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: title <> Integer.to_string(count)}}}
end

defmodule BlazeX.BH05.InertSlots do
  use BlazeX.Component,
    role: :pure,
    schema: [props: [], slots: [{"default", [boundary: :host, max: 256, key: :optional]}]]

  def render(_), do: {:output, {:semantic, 1, %{kind: :group}}}
end

defmodule BlazeX.BH05.CompositionFixtures do
  alias BlazeX.Core.Identity

  alias BlazeX.UITree.{
    Accessibility,
    Binding,
    Document,
    Focus,
    IntentSet,
    Layout,
    Node,
    Selection
  }

  @boundary %{kind: :local, root: "example", owner: "example"}
  def boundary, do: @boundary

  def spec(id, children \\ []),
    do: %{
      module: BlazeX.BH05.PureControl,
      public_id: id,
      site: "example",
      key: id,
      props: %{"kind" => id},
      slots: %{},
      children: children
    }

  def controls,
    do: %{
      "surface" => spec("surface", ["group"]),
      "group" => spec("group", ["action", "field", "collection"]),
      "action" => spec("action"),
      "field" => spec("field"),
      "collection" => spec("collection", ["selection"]),
      "selection" => spec("selection", ["text"]),
      "text" => spec("text")
    }

  def contextual do
    entry = fn key, count ->
      %{
        "key" => key,
        "context" => %{"count" => count},
        "content" => %{"owner" => "example", "caller" => "shell", "id" => "body"}
      }
    end

    %{
      "shell" => %{
        spec("shell")
        | module: BlazeX.BH05.ContextShell,
          props: %{"title" => "Item "},
          slots: %{"default" => [entry.("b", 2), entry.("a", 1)], "footer" => [entry.("end", 3)]}
      },
      "body" => %{
        spec("body")
        | module: BlazeX.BH05.ContextText,
          props: %{"title" => {:caller, "title"}}
      }
    }
  end

  def inert(count) do
    entries = for n <- 1..count, do: %{"content" => %{"kind" => "number", "value" => n}}

    %{
      "inert" => %{
        spec("inert")
        | module: BlazeX.BH05.InertSlots,
          props: %{},
          slots: %{"default" => entries}
      }
    }
  end

  # Independently authored oracle, using public constructors only.
  def oracle do
    {:ok, root} = Identity.new("example")

    ids =
      Enum.reduce(
        [
          {"group", root},
          {"action", "group"},
          {"field", "group"},
          {"collection", "group"},
          {"selection", "collection"},
          {"text", "selection"}
        ],
        %{"surface" => root},
        fn {name, parent}, ids ->
          parent = if is_binary(parent), do: Map.fetch!(ids, parent), else: parent
          {:ok, id} = Identity.child(parent, {name, "example", :child, name})
          Map.put(ids, name, id)
        end
      )

    {:ok, text} = Node.text(ids["text"], "One")
    {:ok, selection} = Node.container(:selection, ids["selection"], [text])
    {:ok, collection} = Node.container(:collection, ids["collection"], [selection])
    {:ok, action} = Node.new(:action, ids["action"])
    {:ok, field} = Node.new(:field, ids["field"])
    {:ok, group} = Node.container(:group, ids["group"], [action, field, collection])
    {:ok, surface} = Node.container(:surface, root, [group])
    {:ok, activate} = Binding.new(:activate, root, ids["action"])
    {:ok, change} = Binding.new(:change, root, ids["field"])
    {:ok, document} = Document.new(surface, [activate, change])
    {:ok, outer} = Layout.new(root, :stack)
    {:ok, inner} = Layout.new(ids["group"], :stack, direction: :row, gap: {:units, 4})
    {:ok, button_a11y} = Accessibility.new(ids["action"], :button, name: "Save")
    {:ok, field_a11y} = Accessibility.new(ids["field"], :text_field, name: "Name")
    {:ok, list_a11y} = Accessibility.new(ids["collection"], :list)
    {:ok, item_a11y} = Accessibility.new(ids["selection"], :list_item, states: %{selected: true})
    {:ok, scope} = Focus.new(root, :scope, restore: :previous)
    {:ok, button_focus} = Focus.new(ids["action"], :target, order: 0)
    {:ok, field_focus} = Focus.new(ids["field"], :target, order: 1, auto_focus: true)

    {:ok, text_selection} =
      Selection.new(ids["field"], :text_range, %{anchor: 0, focus: 0, direction: :forward})

    {:ok, selected} = Selection.new(ids["collection"], :multiple, ["one"])

    {:ok, output} =
      IntentSet.new(document,
        layouts: [outer, inner],
        accessibility: [button_a11y, field_a11y, list_a11y, item_a11y],
        focus: [scope, button_focus, field_focus],
        selections: [text_selection, selected]
      )

    output
  end
end
