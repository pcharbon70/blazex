defmodule BlazeX.Renderer.DOM.Batch do
  @moduledoc "A deterministic full-root DOM projection or disposal batch."

  alias BlazeX.Renderer.Context
  alias BlazeX.Renderer.DOM.{Lowerer, Portable, Projection}
  alias BlazeX.Renderer.Requirements

  @version 1
  @enforce_keys [:version, :owner, :generation, :revision, :transition, :root, :digest]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          version: 1,
          owner: map(),
          generation: pos_integer(),
          revision: non_neg_integer(),
          transition: binary(),
          root: Projection.t() | nil,
          digest: binary()
        }

  @spec project(term(), Context.t()) :: {:ok, t()} | {:error, term()}
  def project(output, %Context{transition: transition} = context)
      when transition in [:mount, :update, :replace] do
    with {:ok, _requirements} <- Requirements.derive(output),
         {:ok, root} <- Lowerer.lower(output) do
      {:ok, build(context, root)}
    end
  end

  def project(_output, _context), do: {:error, :invalid_dom_projection}

  @spec dispose(Context.t()) :: t()
  def dispose(%Context{transition: :dispose} = context), do: build(context, nil)

  @spec to_wire(t()) :: map()
  def to_wire(%__MODULE__{} = batch) do
    %{
      "version" => batch.version,
      "owner" => batch.owner,
      "generation" => batch.generation,
      "revision" => batch.revision,
      "transition" => batch.transition,
      "root" => if(batch.root, do: Projection.to_wire(batch.root), else: nil),
      "digest" => batch.digest
    }
  end

  defp build(context, root) do
    owner = Portable.identity(context.owner)
    transition = Atom.to_string(context.transition)
    root_wire = if root, do: Projection.to_wire(root), else: nil
    canonical = {@version, owner, context.generation, context.revision, transition, root_wire}

    digest =
      canonical
      |> :erlang.term_to_binary([:deterministic])
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    %__MODULE__{
      version: @version,
      owner: owner,
      generation: context.generation,
      revision: context.revision,
      transition: transition,
      root: root,
      digest: digest
    }
  end
end
