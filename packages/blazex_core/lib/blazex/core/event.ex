defmodule BlazeX.Core.Event do
  @moduledoc """
  Experimental version-1 semantic user-intent envelope.

  Event names describe intent rather than a concrete input mechanism. The
  owner identifies the stateful component; the source identifies a node in its
  semantic subtree.
  """

  alias BlazeX.Core.{Identity, Portable}

  @version 1
  @names [
    :activate,
    :change,
    :submit,
    :select,
    :expand,
    :dismiss,
    :move,
    :reorder,
    :increment,
    :decrement,
    :request_open,
    :request_close,
    :request_page
  ]
  @max_sequence 9_223_372_036_854_775_807

  @enforce_keys [:version, :name, :owner, :source, :payload, :sequence]
  defstruct [:version, :name, :owner, :source, :payload, :sequence]

  @type name ::
          :activate
          | :change
          | :submit
          | :select
          | :expand
          | :dismiss
          | :move
          | :reorder
          | :increment
          | :decrement
          | :request_open
          | :request_close
          | :request_page

  @type t :: %__MODULE__{
          version: 1,
          name: name(),
          owner: Identity.t(),
          source: Identity.t(),
          payload: map(),
          sequence: pos_integer()
        }

  @spec version() :: 1
  def version, do: @version

  @spec names() :: [name()]
  def names, do: @names

  @spec name?(term()) :: boolean()
  def name?(name), do: name in @names

  @spec new(name(), Identity.t(), Identity.t(), map(), pos_integer()) ::
          {:ok, t()}
          | {:error,
             :unknown_event
             | :invalid_owner
             | :invalid_source
             | :source_outside_owner
             | :invalid_payload
             | :invalid_sequence}
  def new(name, owner, source, payload \\ %{}, sequence \\ 1) do
    cond do
      not name?(name) ->
        {:error, :unknown_event}

      not Identity.valid?(owner) ->
        {:error, :invalid_owner}

      not Identity.valid?(source) ->
        {:error, :invalid_source}

      not Identity.contains?(owner, source) ->
        {:error, :source_outside_owner}

      not is_map(payload) or not Portable.valid?(payload) ->
        {:error, :invalid_payload}

      not is_integer(sequence) or sequence not in 1..@max_sequence ->
        {:error, :invalid_sequence}

      true ->
        {:ok,
         %__MODULE__{
           version: @version,
           name: name,
           owner: owner,
           source: source,
           payload: payload,
           sequence: sequence
         }}
    end
  end

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{} = event) do
    match?(
      {:ok, %__MODULE__{}},
      new(event.name, event.owner, event.source, event.payload, event.sequence)
    ) and event.version == @version
  end

  def valid?(_event), do: false
end
