defmodule BlazeX.NativeSpike.Batch do
  @moduledoc "A deterministic native-control projection or disposal batch."

  alias BlazeX.NativeSpike.{Lowerer, Portable}
  alias BlazeX.Renderer.{Context, Requirements}

  @version 1
  @enforce_keys [:version, :owner, :generation, :revision, :transition, :root, :digest]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          version: 1,
          owner: map(),
          generation: pos_integer(),
          revision: non_neg_integer(),
          transition: atom(),
          root: BlazeX.NativeSpike.Node.t() | nil,
          digest: binary()
        }

  def project(output, %Context{transition: transition} = context)
      when transition in [:mount, :update, :replace] do
    with {:ok, _requirements} <- Requirements.derive(output),
         {:ok, root} <- Lowerer.lower(output) do
      {:ok, build(context, root)}
    end
  end

  def project(_output, _context), do: {:error, :invalid_native_projection}
  def dispose(%Context{transition: :dispose} = context), do: build(context, nil)

  defp build(context, root) do
    owner = Portable.identity(context.owner)
    canonical = {@version, owner, context.generation, context.revision, context.transition, root}

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
      transition: context.transition,
      root: root,
      digest: digest
    }
  end
end
