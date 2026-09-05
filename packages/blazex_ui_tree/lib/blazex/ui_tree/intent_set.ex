defmodule BlazeX.UITree.IntentSet do
  @moduledoc """
  Version-1 composition of semantic document and portable presentation intent.
  """

  alias BlazeX.UITree.{Accessibility, Document, Focus, Layout, Node, Selection}

  @version 1
  @option_keys [:layouts, :accessibility, :focus, :selections]
  @enforce_keys [:version, :document, :layouts, :accessibility, :focus, :selections]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          version: 1,
          document: Document.t(),
          layouts: [Layout.t()],
          accessibility: [Accessibility.t()],
          focus: [Focus.t()],
          selections: [Selection.t()]
        }

  @spec new(Document.t(), keyword()) :: {:ok, t()} | {:error, atom()}
  def new(document, options \\ [])

  def new(document, options) when is_list(options) do
    if Keyword.keyword?(options) and Enum.all?(Keyword.keys(options), &(&1 in @option_keys)) do
      intent_set = %__MODULE__{
        version: @version,
        document: document,
        layouts: Keyword.get(options, :layouts, []),
        accessibility: Keyword.get(options, :accessibility, []),
        focus: Keyword.get(options, :focus, []),
        selections: Keyword.get(options, :selections, [])
      }

      case validate(intent_set) do
        :ok -> {:ok, intent_set}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_intent_set_options}
    end
  end

  def new(_document, _options), do: {:error, :invalid_intent_set_options}

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = intent_set) do
    with :ok <- validate_version(intent_set),
         :ok <- Document.validate(intent_set.document),
         {:ok, nodes} <- Node.preorder(intent_set.document.root),
         :ok <- validate_list(intent_set.layouts, Layout, :invalid_layouts),
         :ok <- validate_list(intent_set.accessibility, Accessibility, :invalid_accessibility),
         :ok <- validate_list(intent_set.focus, Focus, :invalid_focus),
         :ok <- validate_list(intent_set.selections, Selection, :invalid_selections),
         :ok <- validate_owners(intent_set, nodes),
         :ok <- validate_unique_owners(intent_set),
         :ok <- validate_relationships(intent_set.accessibility, nodes),
         :ok <- validate_accessibility_compatibility(intent_set.accessibility, nodes),
         :ok <- validate_focus(intent_set.focus, nodes),
         :ok <- validate_selections(intent_set.selections, nodes) do
      :ok
    else
      {:error, %BlazeX.UITree.ValidationError{}} -> {:error, :invalid_tree}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate(_intent_set), do: {:error, :malformed_intent_set}

  defp validate_version(%__MODULE__{version: @version}), do: :ok
  defp validate_version(_intent_set), do: {:error, :unsupported_intent_set_version}

  defp validate_list(values, module, error) do
    if proper_list?(values) and Enum.all?(values, &module.valid?/1),
      do: :ok,
      else: {:error, error}
  end

  defp validate_owners(intent_set, nodes) do
    identities = MapSet.new(nodes, & &1.identity)

    annotations =
      intent_set.layouts ++ intent_set.accessibility ++ intent_set.focus ++ intent_set.selections

    if Enum.all?(annotations, &MapSet.member?(identities, &1.owner)),
      do: :ok,
      else: {:error, :annotation_owner_missing}
  end

  defp validate_unique_owners(intent_set) do
    if Enum.all?(
         [intent_set.layouts, intent_set.accessibility, intent_set.focus, intent_set.selections],
         &unique_owners?/1
       ),
       do: :ok,
       else: {:error, :duplicate_annotation_owner}
  end

  defp unique_owners?(annotations) do
    owners = Enum.map(annotations, & &1.owner)
    length(owners) == MapSet.size(MapSet.new(owners))
  end

  defp validate_relationships(accessibility, nodes) do
    identities = MapSet.new(nodes, & &1.identity)

    if Enum.all?(accessibility, fn annotation ->
         annotation.relationships
         |> Map.values()
         |> List.flatten()
         |> Enum.all?(&MapSet.member?(identities, &1))
       end),
       do: :ok,
       else: {:error, :accessibility_relationship_target_missing}
  end

  defp validate_accessibility_compatibility(accessibility, nodes) do
    nodes_by_identity = Map.new(nodes, &{&1.identity, &1.kind})

    allowed = %{
      text: [:generic, :text, :status],
      group: [:generic, :group, :dialog, :status],
      action: [:generic, :button],
      field: [:generic, :text_field, :checkbox],
      selection: [:generic, :checkbox, :list_item],
      collection: [:generic, :group, :list],
      surface: [:generic, :group, :dialog]
    }

    if Enum.all?(accessibility, fn annotation ->
         annotation.role in Map.fetch!(allowed, Map.fetch!(nodes_by_identity, annotation.owner))
       end),
       do: :ok,
       else: {:error, :accessibility_role_incompatible}
  end

  defp validate_focus(focus, nodes) do
    nodes_by_identity = Map.new(nodes, &{&1.identity, &1.kind})
    targets = Enum.filter(focus, &(&1.behavior == :target))
    scopes = Enum.filter(focus, &(&1.behavior == :scope))
    orders = Enum.map(targets, & &1.order)

    cond do
      length(orders) != MapSet.size(MapSet.new(orders)) ->
        {:error, :duplicate_focus_order}

      Enum.count(targets, & &1.auto_focus) > 1 ->
        {:error, :multiple_auto_focus_targets}

      not Enum.all?(
        targets,
        &(Map.fetch!(nodes_by_identity, &1.owner) in [:action, :field, :selection])
      ) ->
        {:error, :focus_target_incompatible}

      not Enum.all?(scopes, &(Map.fetch!(nodes_by_identity, &1.owner) in [:group, :surface])) ->
        {:error, :focus_scope_incompatible}

      true ->
        :ok
    end
  end

  defp validate_selections(selections, nodes) do
    nodes_by_identity = Map.new(nodes, &{&1.identity, &1.kind})

    if Enum.all?(selections, fn selection ->
         node_kind = Map.fetch!(nodes_by_identity, selection.owner)

         case selection.kind do
           :text_range -> node_kind == :field
           kind when kind in [:single, :multiple] -> node_kind in [:selection, :collection]
           :none -> node_kind in [:field, :selection, :collection]
         end
       end),
       do: :ok,
       else: {:error, :selection_kind_incompatible}
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false
end
