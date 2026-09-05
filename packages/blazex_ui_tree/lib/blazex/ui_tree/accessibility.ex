defmodule BlazeX.UITree.Accessibility do
  @moduledoc """
  Version-1 platform-neutral accessibility intent for one semantic node.
  """

  alias BlazeX.Core.Identity

  @version 1
  @roles [
    :generic,
    :text,
    :group,
    :button,
    :text_field,
    :checkbox,
    :list,
    :list_item,
    :dialog,
    :status
  ]
  @state_keys [:disabled, :expanded, :selected, :checked, :invalid, :required, :readonly, :busy]
  @relationship_keys [:labelled_by, :described_by, :controls, :owns, :error_message]
  @live_values [:off, :polite, :assertive]
  @option_keys [:name, :description, :states, :relationships, :live]
  @max_text_bytes 1_024

  @enforce_keys [:version, :owner, :role, :name, :description, :states, :relationships, :live]
  defstruct @enforce_keys

  @type role ::
          :generic
          | :text
          | :group
          | :button
          | :text_field
          | :checkbox
          | :list
          | :list_item
          | :dialog
          | :status
  @type live :: :off | :polite | :assertive
  @type t :: %__MODULE__{
          version: 1,
          owner: Identity.t(),
          role: role(),
          name: binary() | nil,
          description: binary() | nil,
          states: map(),
          relationships: %{optional(atom()) => [Identity.t()]},
          live: live()
        }

  @spec roles() :: [role()]
  def roles, do: @roles

  @spec state_keys() :: [atom()]
  def state_keys, do: @state_keys

  @spec relationship_keys() :: [atom()]
  def relationship_keys, do: @relationship_keys

  @spec live_values() :: [live()]
  def live_values, do: @live_values

  @spec new(Identity.t(), role(), keyword()) :: {:ok, t()} | {:error, atom()}
  def new(owner, role, options \\ [])

  def new(owner, role, options) when is_list(options) do
    if Keyword.keyword?(options) and Enum.all?(Keyword.keys(options), &(&1 in @option_keys)) do
      accessibility = %__MODULE__{
        version: @version,
        owner: owner,
        role: role,
        name: Keyword.get(options, :name),
        description: Keyword.get(options, :description),
        states: Keyword.get(options, :states, %{}),
        relationships: Keyword.get(options, :relationships, %{}),
        live: Keyword.get(options, :live, :off)
      }

      case validate(accessibility) do
        :ok -> {:ok, accessibility}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :invalid_accessibility_options}
    end
  end

  def new(_owner, _role, _options), do: {:error, :invalid_accessibility_options}

  @spec validate(term()) :: :ok | {:error, atom()}
  def validate(%__MODULE__{} = accessibility) do
    cond do
      accessibility.version != @version ->
        {:error, :unsupported_accessibility_version}

      not Identity.valid?(accessibility.owner) ->
        {:error, :invalid_accessibility_owner}

      accessibility.role not in @roles ->
        {:error, :unknown_accessibility_role}

      not valid_text?(accessibility.name) ->
        {:error, :invalid_accessibility_name}

      not valid_text?(accessibility.description) ->
        {:error, :invalid_accessibility_description}

      not valid_states?(accessibility.states) ->
        {:error, :invalid_accessibility_states}

      not valid_relationships?(accessibility.relationships) ->
        {:error, :invalid_accessibility_relationships}

      accessibility.live not in @live_values ->
        {:error, :invalid_live_intent}

      true ->
        :ok
    end
  end

  def validate(_accessibility), do: {:error, :malformed_accessibility}

  @spec valid?(term()) :: boolean()
  def valid?(accessibility), do: validate(accessibility) == :ok

  defp valid_text?(nil), do: true

  defp valid_text?(value) when is_binary(value),
    do: byte_size(value) in 1..@max_text_bytes and String.valid?(value)

  defp valid_text?(_value), do: false

  defp valid_states?(states) when is_map(states) and not is_struct(states) do
    Enum.all?(states, fn
      {:checked, value} -> value in [true, false, :mixed]
      {key, value} -> key in @state_keys and is_boolean(value)
    end)
  end

  defp valid_states?(_states), do: false

  defp valid_relationships?(relationships)
       when is_map(relationships) and not is_struct(relationships) do
    Enum.all?(relationships, fn {key, targets} ->
      key in @relationship_keys and proper_list?(targets) and targets != [] and
        Enum.all?(targets, &Identity.valid?/1) and
        length(targets) == MapSet.size(MapSet.new(targets))
    end)
  end

  defp valid_relationships?(_relationships), do: false

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_improper), do: false
end
