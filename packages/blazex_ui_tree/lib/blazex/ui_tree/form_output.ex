defmodule BlazeX.UITree.FormOutput do
  @moduledoc "Additive version-1 form output. Existing presentation sets remain unchanged."
  alias BlazeX.UITree.{FormState, IntentSet, Node}
  alias BlazeX.Core.Identity
  defstruct version: 1, intent: nil, forms: []

  def new(intent, forms) do
    output = %__MODULE__{intent: intent, forms: forms}

    case validate(output) do
      :ok -> {:ok, output}
      error -> error
    end
  end

  def validate(%__MODULE__{version: 1, intent: intent, forms: forms}) do
    with :ok <- IntentSet.validate(intent),
         {:ok, nodes} <- Node.preorder(intent.document.root),
         true <- is_list(forms) and length(forms) <= 32 and Enum.all?(forms, &FormState.valid?/1),
         true <- length(Enum.uniq_by(forms, & &1.owner)) == length(forms) do
      index = Map.new(nodes, &{&1.identity, &1})
      claims = Enum.flat_map(forms, fn f -> [f.owner | Enum.map(f.choices, & &1.owner)] end)

      valid =
        length(Enum.uniq(claims)) == length(claims) and
          Enum.all?(forms, fn f ->
            node = index[f.owner]

            node != nil and
              if(f.kind in [:text, :check],
                do: node.kind == :field and node.children == [],
                else: node.kind == :collection
              ) and
              Enum.all?(f.choices, fn choice ->
                child = index[choice.owner]

                child != nil and child.kind == :selection and child.children == [] and
                  Identity.contains?(f.owner, choice.owner)
              end) and
              Enum.all?(
                intent.selections,
                &(&1.owner != f.owner or (f.kind == :text and &1.kind in [:none, :text_range]))
              )
          end)

      if valid, do: :ok, else: {:error, :incompatible_form_owner}
    else
      _ -> {:error, :invalid_form_output}
    end
  rescue
    _ -> {:error, :invalid_form_output}
  end

  def validate(_), do: {:error, :invalid_form_output}
end
