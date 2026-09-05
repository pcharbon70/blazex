defmodule BlazeX.UITree.Document do
  @moduledoc """
  Version-1 semantic tree root plus validated event bindings.
  """

  alias BlazeX.Core.Event
  alias BlazeX.UITree.{Binding, Node}

  @version 1
  @enforce_keys [:version, :root, :bindings]
  defstruct [:version, :root, :bindings]

  @type t :: %__MODULE__{version: 1, root: Node.t(), bindings: [Binding.t()]}

  @spec new(Node.t(), [Binding.t()]) :: {:ok, t()} | {:error, atom()}
  def new(root, bindings \\ []) do
    document = %__MODULE__{version: @version, root: root, bindings: bindings}

    case validate(document) do
      :ok -> {:ok, document}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{version: @version, root: root, bindings: bindings}) do
    with :ok <- Node.validate(root),
         :ok <- validate_binding_list(bindings),
         {:ok, nodes} <- Node.preorder(root),
         :ok <- validate_bindings(bindings, root, nodes) do
      :ok
    else
      {:error, %BlazeX.UITree.ValidationError{}} -> {:error, :invalid_tree}
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_binding}
    end
  end

  def validate(%__MODULE__{}), do: {:error, :unsupported_document_version}
  def validate(_document), do: {:error, :malformed_document}

  @spec resolve(t(), Event.t()) :: {:ok, Binding.t()} | {:error, atom()}
  def resolve(%__MODULE__{} = document, %Event{} = event) do
    with :ok <- validate(document),
         :ok <- validate_event(event) do
      case Enum.find(document.bindings, fn binding ->
             binding.event == event.name and binding.owner == event.owner and
               binding.source == event.source
           end) do
        nil -> {:error, :unbound_event}
        binding -> {:ok, binding}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def resolve(_document, _event), do: {:error, :invalid_event}

  defp validate_bindings(bindings, root, nodes) do
    node_identities = MapSet.new(nodes, & &1.identity)

    cond do
      Enum.any?(bindings, &(&1.owner != root.identity)) ->
        {:error, :binding_owner_mismatch}

      Enum.any?(bindings, &(not MapSet.member?(node_identities, &1.source))) ->
        {:error, :binding_source_missing}

      duplicate_binding?(bindings) ->
        {:error, :duplicate_binding}

      true ->
        :ok
    end
  end

  defp duplicate_binding?(bindings) do
    keys = Enum.map(bindings, &{&1.source, &1.event})
    length(keys) != MapSet.size(MapSet.new(keys))
  end

  defp validate_binding_list(bindings) do
    cond do
      not proper_list?(bindings) -> {:error, :invalid_bindings}
      not Enum.all?(bindings, &Binding.valid?/1) -> {:error, :invalid_binding}
      true -> :ok
    end
  end

  defp validate_event(event) do
    if Event.valid?(event), do: :ok, else: {:error, :invalid_event}
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false
end
