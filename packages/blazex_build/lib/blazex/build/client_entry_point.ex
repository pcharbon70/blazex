defmodule BlazeX.Build.ClientEntryPoint do
  @moduledoc "A bounded, atom-safe client root declaration for reachability analysis."

  @enforce_keys [:id, :module]
  defstruct @enforce_keys

  @id ~r/^[a-z][a-z0-9_-]{0,63}$/
  @module ~r/^(?:Elixir\.)?[A-Z][A-Za-z0-9_.]{0,254}$/

  def new!(attributes) when is_map(attributes) do
    entry = struct!(__MODULE__, attributes)

    unless is_binary(entry.id) and Regex.match?(@id, entry.id),
      do: raise(ArgumentError, "client entrypoint id must be a bounded lowercase identifier")

    unless is_binary(entry.module) and Regex.match?(@module, entry.module),
      do: raise(ArgumentError, "client entrypoint module must be a bounded module string")

    %{entry | module: normalize_module(entry.module)}
  end

  defp normalize_module("Elixir." <> _ = module), do: module
  defp normalize_module(module), do: "Elixir." <> module
end
