defmodule BlazeX.Renderer.Headless.Snapshot do
  @moduledoc """
  Canonical nonvisual observation of one accepted semantic output.
  """

  alias BlazeX.Renderer.Context
  alias BlazeX.Renderer.Headless.Normalizer
  alias BlazeX.Renderer.Requirements

  @version 1
  @enforce_keys [
    :version,
    :owner,
    :generation,
    :revision,
    :tree,
    :bindings,
    :layouts,
    :accessibility,
    :focus,
    :selections,
    :digest
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          version: 1,
          owner: BlazeX.Core.Identity.t(),
          generation: pos_integer(),
          revision: non_neg_integer(),
          tree: tuple(),
          bindings: [tuple()],
          layouts: [tuple()],
          accessibility: [tuple()],
          focus: [tuple()],
          selections: [tuple()],
          digest: binary()
        }

  @spec build(term(), Context.t()) :: {:ok, t()} | {:error, atom()}
  def build(output, %Context{} = context) do
    with {:ok, _requirements} <- Requirements.derive(output),
         {:ok, normalized} <- Normalizer.normalize(output) do
      canonical =
        {:headless_snapshot, @version, Normalizer.identity(context.owner), context.generation,
         context.revision, normalized.tree, normalized.bindings, normalized.layouts,
         normalized.accessibility, normalized.focus, normalized.selections}

      digest =
        canonical
        |> :erlang.term_to_binary([:deterministic])
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)

      {:ok,
       struct!(__MODULE__,
         version: @version,
         owner: context.owner,
         generation: context.generation,
         revision: context.revision,
         tree: normalized.tree,
         bindings: normalized.bindings,
         layouts: normalized.layouts,
         accessibility: normalized.accessibility,
         focus: normalized.focus,
         selections: normalized.selections,
         digest: digest
       )}
    end
  end

  def build(_output, _context), do: {:error, :invalid_renderer_context}
end
