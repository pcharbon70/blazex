defmodule BlazeX.Component.Input do
  @moduledoc """
  Validates the immutable candidate callback envelope without invoking code.
  Props/slots are portable maps, not schema-validated values. Context access
  is a list of declared names only; resolution and secrets are not supplied.
  """
  alias BlazeX.Component.Contract
  alias BlazeX.Core.{Identity, Portable}

  @keys [
    :role,
    :transition,
    :props,
    :slots,
    :state,
    :payload,
    :root,
    :identity,
    :generation,
    :revision,
    :sequence,
    :capabilities,
    :context_keys
  ]
  @reserved [:host, :renderer, :dom, :socket, :pid, :process, :secret, :resource, :__struct__]
  @max_counter 9_007_199_254_740_991

  @spec validate(term()) :: :ok | {:error, map()}
  def validate(input) do
    if valid?(input), do: :ok, else: error(:invalid_input)
  end

  defp valid?(%{contexts: contexts} = input) when map_size(input) == length(@keys) + 1 do
    is_map(contexts) and map_size(contexts) <= 16 and
      BlazeX.Component.Action.public?(contexts) and
      Map.has_key?(input, :context_keys) and names?(input.context_keys) and
      Enum.all?(Map.keys(contexts), &(&1 in input.context_keys)) and
      valid?(Map.delete(input, :contexts))
  end

  defp valid?(input) when is_map(input) and map_size(input) == length(@keys) do
    with true <- Enum.all?(@keys, &Map.has_key?(input, &1)),
         true <- Contract.callback?(input.role, input.transition),
         true <- plain_map?(input.props) and plain_map?(input.slots),
         true <- identity?(input.root) and identity?(input.identity),
         true <- input.root.path == [],
         true <- input.identity.root == input.root.root,
         true <-
           input.identity.generation == input.generation and
             input.root.generation == input.generation,
         true <- input.role != :root or input.identity == input.root,
         true <- input.role != :stateful or input.identity.path != [],
         true <- counter?(input.revision) and counter?(input.sequence),
         true <- names?(input.capabilities) and names?(input.context_keys) do
      initial = input.role == :pure or input.transition in [:mount, :init]
      state?(input.state, initial) and payload?(input.payload, input.transition)
    else
      _ -> false
    end
  end

  defp valid?(_input), do: false

  @doc "Portable data guard, not schema validation or secret-content detection."
  @spec portable?(term()) :: boolean()
  def portable?(value), do: Portable.valid?(value) and neutral?(value)

  defp neutral?(value) when is_map(value) do
    Enum.all?(value, fn {key, child} ->
      key not in @reserved and key not in Enum.map(@reserved, &Atom.to_string/1) and
        neutral?(key) and neutral?(child)
    end)
  end

  defp neutral?(value) when is_list(value), do: Enum.all?(value, &neutral?/1)

  defp neutral?(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.all?(&neutral?/1)

  defp neutral?(_value), do: true

  defp identity?(%{root: root, path: path, generation: generation} = identity)
       when map_size(identity) == 3 do
    Identity.valid?(%Identity{root: root, path: path, generation: generation}) and
      generation <= @max_counter
  end

  defp identity?(_identity), do: false
  defp counter?(value), do: is_integer(value) and value >= 0 and value <= @max_counter
  defp plain_map?(value), do: is_map(value) and portable?(value)
  defp state?(:absent, true), do: true
  defp state?({:present, value}, false), do: portable?(value)
  defp state?(_state, _initial), do: false

  defp payload?(payload, transition)
       when transition in [
              :handle_event,
              :handle_info,
              :commit_ack,
              :effect_result,
              :failure,
              :retry,
              :dispose,
              :terminate
            ] do
    case payload do
      {:present, value} -> portable?(value)
      _ -> false
    end
  end

  defp payload?(payload, _transition), do: payload == :absent

  @spec names?(term()) :: boolean()
  def names?(names) do
    Portable.valid?(names) and is_list(names) and
      Enum.all?(names, &(is_binary(&1) and byte_size(&1) in 1..128)) and
      names == Enum.sort(Enum.uniq(names))
  end

  @spec error(atom()) :: {:error, map()}
  def error(code) when code in [:invalid_input, :invalid_result],
    do: {:error, %{code: code, contract: Contract.version()}}

  def error(_code), do: error(:invalid_input)
end
