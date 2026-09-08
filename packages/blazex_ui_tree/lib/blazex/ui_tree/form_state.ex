defmodule BlazeX.UITree.FormState do
  @moduledoc "Version-1 internal controlled state with explicit stable choices and edit acknowledgement."
  alias BlazeX.Core.Identity

  @keys [
    :owner,
    :kind,
    :value,
    :choices,
    :edit_sequence,
    :disabled,
    :readonly,
    :required,
    :invalid,
    :indeterminate
  ]
  defstruct version: 1,
            owner: nil,
            kind: :text,
            value: "",
            choices: [],
            edit_sequence: 0,
            disabled: false,
            readonly: false,
            required: false,
            invalid: false,
            indeterminate: false

  def new(owner, kind, value, options \\ []) do
    if Keyword.keyword?(options) and
         Enum.all?(Keyword.keys(options), &(&1 in (@keys -- [:owner, :kind, :value]))) do
      state = struct(__MODULE__, [{:owner, owner}, {:kind, kind}, {:value, value} | options])

      case validate(state) do
        :ok -> {:ok, state}
        error -> error
      end
    else
      {:error, :invalid_form_options}
    end
  end

  def validate(%__MODULE__{version: 1} = state) do
    valid =
      Identity.valid?(state.owner) and state.kind in [:text, :check, :single, :multiple] and
        is_integer(state.edit_sequence) and state.edit_sequence in 0..9_007_199_254_740_991 and
        Enum.all?(
          [state.disabled, state.readonly, state.required, state.invalid, state.indeterminate],
          &is_boolean/1
        ) and
        (not state.indeterminate or state.kind == :check) and choices?(state.choices) and
        value?(state)

    if valid, do: :ok, else: {:error, :invalid_form_state}
  rescue
    _ -> {:error, :invalid_form_state}
  end

  def validate(_), do: {:error, :invalid_form_state}
  def valid?(state), do: validate(state) == :ok
  defp text?(v, max), do: is_binary(v) and String.valid?(v) and byte_size(v) <= max

  defp choices?(choices) do
    is_list(choices) and length(choices) <= 32 and
      Enum.all?(choices, fn
        %{value: value, owner: owner} = choice ->
          map_size(choice) == 2 and text?(value, 128) and value != "" and Identity.valid?(owner)

        _ ->
          false
      end) and length(Enum.uniq_by(choices, & &1.value)) == length(choices) and
      length(Enum.uniq_by(choices, & &1.owner)) == length(choices)
  end

  defp value?(%{kind: :text, value: v, choices: []}), do: text?(v, 2048)
  defp value?(%{kind: :check, value: v, choices: []}), do: is_boolean(v)

  defp value?(%{kind: :single, value: v, choices: choices}),
    do: is_nil(v) or Enum.any?(choices, &(&1.value == v))

  defp value?(%{kind: :multiple, value: v, choices: choices}),
    do:
      is_list(v) and length(v) <= 32 and Enum.uniq(v) == v and
        Enum.all?(v, fn value -> Enum.any?(choices, &(&1.value == value)) end)

  defp value?(_), do: false
end
