defmodule BlazeX.Renderer.DOM.Lowerer do
  @moduledoc false

  alias BlazeX.Renderer.DOM.{FocusIntent, Listener, Portable, Projection, SelectionIntent}

  alias BlazeX.UITree.{
    Accessibility,
    Document,
    IntentSet,
    Layout,
    Node,
    TokenRef
  }

  @base_tags %{
    text: "span",
    group: "div",
    action: "button",
    field: "input",
    selection: "button",
    collection: "ul",
    surface: "section"
  }
  @role_tags %{
    button: "button",
    text_field: "input",
    checkbox: "input",
    list: "ul",
    list_item: "li"
  }
  @roles %{
    generic: nil,
    text: nil,
    group: "group",
    button: "button",
    text_field: "textbox",
    checkbox: "checkbox",
    list: "list",
    list_item: "listitem",
    dialog: "dialog",
    status: "status"
  }
  @relationships %{
    labelled_by: "aria-labelledby",
    described_by: "aria-describedby",
    controls: "aria-controls",
    owns: "aria-owns",
    error_message: "aria-errormessage"
  }

  @spec lower(Node.t() | Document.t() | IntentSet.t()) :: {:ok, Projection.t()} | {:error, atom()}
  def lower(%Node{} = node), do: lower_parts(node, [], [], [], [], [])

  def lower(%Document{} = document),
    do: lower_parts(document.root, document.bindings, [], [], [], [])

  def lower(%IntentSet{} = intent_set) do
    lower_parts(
      intent_set.document.root,
      intent_set.document.bindings,
      intent_set.layouts,
      intent_set.accessibility,
      intent_set.focus,
      intent_set.selections
    )
  end

  def lower(_output), do: {:error, :invalid_semantic_output}

  defp lower_parts(root, bindings, layouts, accessibility, focus, selections) do
    annotations = %{
      bindings: Enum.group_by(bindings, & &1.source),
      layouts: Map.new(layouts, &{&1.owner, &1}),
      accessibility: Map.new(accessibility, &{&1.owner, &1}),
      focus: Map.new(focus, &{&1.owner, &1}),
      selections: Map.new(selections, &{&1.owner, &1})
    }

    {:ok, lower_node(root, annotations)}
  end

  defp lower_node(%Node{} = node, annotations) do
    accessibility = annotations.accessibility[node.identity]
    layout = annotations.layouts[node.identity]
    focus = annotations.focus[node.identity]
    selection = annotations.selections[node.identity]

    %Projection{
      version: Projection.version(),
      id: Portable.id(node.identity),
      tag: tag(node.kind, accessibility),
      text: node.content,
      attributes: attributes(node, accessibility, layout),
      listeners:
        annotations.bindings
        |> Map.get(node.identity, [])
        |> Enum.map(&Listener.new/1)
        |> Enum.sort_by(& &1.semantic),
      focus: focus && FocusIntent.from(focus),
      selection: selection && SelectionIntent.from(selection),
      children: Enum.map(node.children, &lower_node(&1, annotations))
    }
  end

  defp tag(_kind, %Accessibility{role: role}) when is_map_key(@role_tags, role),
    do: Map.fetch!(@role_tags, role)

  defp tag(kind, _accessibility), do: Map.fetch!(@base_tags, kind)

  defp attributes(node, accessibility, layout) do
    %{"data-bx-kind" => Atom.to_string(node.kind)}
    |> add_input_type(accessibility)
    |> add_accessibility(accessibility)
    |> add_layout(layout)
  end

  defp add_input_type(attributes, %Accessibility{role: :checkbox}),
    do: Map.put(attributes, "type", "checkbox")

  defp add_input_type(attributes, _accessibility), do: attributes

  defp add_accessibility(attributes, nil), do: attributes

  defp add_accessibility(attributes, %Accessibility{} = accessibility) do
    attributes
    |> put_optional("role", Map.fetch!(@roles, accessibility.role))
    |> put_optional("aria-label", accessibility.name)
    |> put_optional("aria-description", accessibility.description)
    |> put_states(accessibility.states)
    |> put_relationships(accessibility.relationships)
    |> put_live(accessibility.live)
  end

  defp put_states(attributes, states) do
    Enum.reduce(states, attributes, fn {key, value}, current ->
      Map.put(current, "aria-" <> state_name(key), state_value(value))
    end)
  end

  defp state_name(:readonly), do: "readonly"
  defp state_name(key), do: Atom.to_string(key)
  defp state_value(value) when is_boolean(value), do: to_string(value)
  defp state_value(:mixed), do: "mixed"

  defp put_relationships(attributes, relationships) do
    Enum.reduce(relationships, attributes, fn {key, targets}, current ->
      value = targets |> Enum.map(&Portable.id/1) |> Enum.join(" ")
      Map.put(current, Map.fetch!(@relationships, key), value)
    end)
  end

  defp put_live(attributes, :off), do: attributes
  defp put_live(attributes, live), do: Map.put(attributes, "aria-live", Atom.to_string(live))

  defp add_layout(attributes, nil), do: attributes

  defp add_layout(attributes, %Layout{} = layout) do
    attributes
    |> Map.put("data-bx-layout-mode", Atom.to_string(layout.mode))
    |> Map.put("data-bx-layout-direction", Atom.to_string(layout.direction))
    |> Map.put("data-bx-layout-align", Atom.to_string(layout.align))
    |> Map.put("data-bx-layout-gap", metric(layout.gap))
    |> Map.put("data-bx-layout-padding", padding(layout.padding))
    |> Map.put("data-bx-layout-width", metric(layout.width))
    |> Map.put("data-bx-layout-height", metric(layout.height))
    |> put_optional_metric("data-bx-layout-min-width", layout.min_width)
    |> put_optional_metric("data-bx-layout-min-height", layout.min_height)
    |> put_optional_metric("data-bx-layout-max-width", layout.max_width)
    |> put_optional_metric("data-bx-layout-max-height", layout.max_height)
    |> Map.put("data-bx-layout-grow", Integer.to_string(layout.grow))
    |> Map.put("data-bx-layout-overflow", Atom.to_string(layout.overflow))
    |> put_virtualization(layout.virtualization)
  end

  defp metric(value) when value in [:auto, :content, :fill], do: Atom.to_string(value)
  defp metric({:units, value}) when is_integer(value), do: "units:" <> Integer.to_string(value)
  defp metric({:units, value}), do: "units:" <> :erlang.float_to_binary(value, [:compact])

  defp metric({:token, %TokenRef{} = token}),
    do: "token:" <> Atom.to_string(token.category) <> ":" <> Portable.encoded_token(token.name)

  defp padding({top, right, bottom, left}),
    do: Enum.map_join([top, right, bottom, left], "|", &metric/1)

  defp put_optional(attributes, _key, nil), do: attributes
  defp put_optional(attributes, key, value), do: Map.put(attributes, key, value)
  defp put_optional_metric(attributes, _key, nil), do: attributes
  defp put_optional_metric(attributes, key, value), do: Map.put(attributes, key, metric(value))
  defp put_virtualization(attributes, nil), do: attributes

  defp put_virtualization(attributes, value) do
    Map.put(
      attributes,
      "data-bx-layout-virtualization",
      Enum.join([Atom.to_string(value.axis), metric(value.estimated_extent), value.overscan], "|")
    )
  end
end
