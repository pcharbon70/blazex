defmodule BlazeX.Renderer.Artifact do
  @moduledoc """
  Versioned envelope for backend-owned renderer output.

  The generic renderer contract validates only this envelope. Each backend
  owns and validates the value stored inside it.
  """

  @version 1
  @enforce_keys [:version, :format, :value]
  defstruct [:version, :format, :value]

  @type t :: %__MODULE__{version: 1, format: atom(), value: term()}

  @spec new(atom(), term()) :: {:ok, t()} | {:error, :invalid_artifact_format}
  def new(format, value) when is_atom(format) and not is_nil(format),
    do: {:ok, %__MODULE__{version: @version, format: format, value: value}}

  def new(_format, _value), do: {:error, :invalid_artifact_format}

  @spec valid?(term()) :: boolean()
  def valid?(%__MODULE__{version: @version, format: format}),
    do: is_atom(format) and not is_nil(format)

  def valid?(_artifact), do: false
end
