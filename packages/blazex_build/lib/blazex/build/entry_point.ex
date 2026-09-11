defmodule BlazeX.Build.EntryPoint do
  @moduledoc "Validated input for the experimental BH-06 candidate pipeline."

  @enforce_keys [:id, :module, :bundle, :runtime_module, :runtime_wasm, :host, :document]
  defstruct @enforce_keys ++ [compatibility: %{}]

  @id ~r/^[a-z][a-z0-9_-]{0,63}$/
  @module ~r/^Elixir\.[A-Z][A-Za-z0-9_.]*$/

  def new!(%__MODULE__{} = spec), do: validate!(spec)

  def new!(attributes) when is_map(attributes),
    do: attributes |> then(&struct!(__MODULE__, &1)) |> validate!()

  defp validate!(spec) do
    unless is_binary(spec.id) and Regex.match?(@id, spec.id),
      do: raise(ArgumentError, "entrypoint id must be a bounded lowercase identifier")

    unless is_binary(spec.module) and Regex.match?(@module, spec.module),
      do: raise(ArgumentError, "entrypoint module must be a fully-qualified Elixir module string")

    for field <- [:bundle, :runtime_module, :runtime_wasm, :host, :document] do
      path = Map.fetch!(spec, field)

      unless is_binary(path) and Path.type(path) == :absolute and File.regular?(path),
        do: raise(ArgumentError, "#{field} must be an existing absolute regular file")
    end

    unless is_map(spec.compatibility) and
             Enum.all?(spec.compatibility, fn {key, value} ->
               is_binary(key) and is_binary(value) and byte_size(key) in 1..128 and
                 byte_size(value) in 1..128
             end),
           do: raise(ArgumentError, "compatibility must contain bounded string pairs")

    spec
  end
end
