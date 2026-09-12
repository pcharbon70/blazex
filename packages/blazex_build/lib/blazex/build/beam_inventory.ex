defmodule BlazeX.Build.BeamInventory do
  @moduledoc "Deterministic facts from a trusted, explicit set of BEAM files."

  def scan!(paths) when is_list(paths) do
    records = Enum.map(paths, &read!(&1, nil))
    finish!(records)
  end

  def scan!(_), do: raise(ArgumentError, "BEAM inventory must be a list of paths")

  def scan_owned!(entries) when is_list(entries) do
    records =
      Enum.map(entries, fn
        {path, application} when is_binary(path) and is_binary(application) ->
          unless Regex.match?(~r/^[a-z][a-z0-9_]{0,63}$/, application),
            do: raise(ArgumentError, "BEAM application ownership is invalid")

          read!(path, application)

        _ ->
          raise ArgumentError, "owned BEAM inputs must be path/application string pairs"
      end)

    finish!(records)
  end

  def scan_owned!(_), do: raise(ArgumentError, "owned BEAM inventory must be a list")

  defp finish!(records) do
    duplicates =
      records
      |> Enum.group_by(& &1["module"])
      |> Enum.filter(fn {_module, rows} -> length(rows) > 1 end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    if duplicates != [],
      do: raise(ArgumentError, "duplicate BEAM modules: #{Enum.join(duplicates, ", ")}")

    Enum.sort_by(records, & &1["module"])
  end

  defp read!(path, application) when is_binary(path) do
    unless Path.type(path) == :absolute and Path.extname(path) == ".beam" and File.regular?(path),
      do: raise(ArgumentError, "BEAM input must be an absolute regular .beam file")

    case :beam_lib.chunks(String.to_charlist(path), [:imports, :exports, :attributes]) do
      {:ok, {module, chunks}} ->
        record = %{
          "module" => module_name(module),
          "sha256" => digest(path),
          "imports" => normalize_functions(Keyword.fetch!(chunks, :imports)),
          "exports" => normalize_exports(Keyword.fetch!(chunks, :exports)),
          "attributes" => normalize_attributes(Keyword.fetch!(chunks, :attributes))
        }

        if application, do: Map.put(record, "application", application), else: record

      {:error, _, reason} ->
        raise ArgumentError, "malformed BEAM input: #{inspect(reason)}"
    end
  end

  defp read!(_, _), do: raise(ArgumentError, "BEAM input path must be a string")

  defp normalize_functions(functions) do
    functions
    |> Enum.map(fn {module, function, arity} ->
      %{"module" => module_name(module), "function" => Atom.to_string(function), "arity" => arity}
    end)
    |> Enum.sort_by(&{&1["module"], &1["function"], &1["arity"]})
  end

  defp normalize_exports(functions) do
    functions
    |> Enum.map(fn {function, arity} ->
      %{"function" => Atom.to_string(function), "arity" => arity}
    end)
    |> Enum.sort_by(&{&1["function"], &1["arity"]})
  end

  defp normalize_attributes(attributes) do
    attributes
    |> Keyword.keys()
    |> Enum.map(&Atom.to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp module_name(module) when is_atom(module), do: Atom.to_string(module)
  defp digest(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
end
