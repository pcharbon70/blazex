defmodule BlazeX.Renderer.DOM.EffectBatch do
  @moduledoc "Internal bounded effect companion; legacy Effect and DOM contracts remain unchanged."
  alias BlazeX.Effects.{Effect, Result}
  alias BlazeX.Renderer.DOM.Protocol.Codec

  def grants?(nil), do: true
  def grants?(grants), do: grants in [[], [:time]]

  def valid?(effects, owner, nil), do: effects == [] and owner != nil

  def valid?(effects, owner, grants) when is_list(effects) do
    length(effects) <= 16 and Enum.all?(effects, &valid_effect?(&1, owner, grants)) and
      length(effects) == MapSet.size(MapSet.new(Enum.map(effects, & &1.id)))
  end

  def valid?(_, _, _), do: false

  defp valid_effect?(%Effect{} = e, owner, grants) do
    Effect.valid?(e) and e.owner == owner and e.capability == :time and :time in grants and
      e.operation == :schedule and is_binary(e.id) and
      Regex.match?(~r/\A[A-Za-z0-9_-]{1,64}\z/, e.id) and
      is_map(e.payload) and Map.keys(e.payload) == ["delay_ms"] and
      is_integer(e.payload["delay_ms"]) and e.payload["delay_ms"] in 0..250 and
      is_integer(e.timeout_ms) and e.timeout_ms in 1..500
  end

  defp valid_effect?(_, _, _), do: false

  def wrap(continuity, effects) do
    tx = continuity["transaction"]

    requests =
      Enum.map(effects, fn e ->
        %{
          "id" => e.id,
          "owner" => tx["root"],
          "generation" => tx["generation"],
          "revision" => tx["target_revision"],
          "capability" => "time",
          "operation" => "schedule",
          "payload" => e.payload,
          "timeout_ms" => e.timeout_ms,
          "fallback" => Atom.to_string(e.fallback),
          "barrier" => "post-commit",
          "depends" => []
        }
      end)

    body = %{
      "protocol" => "blazex.dom-effects/1",
      "continuity" => continuity,
      "effects" => requests
    }

    Map.put(body, "digest", Codec.digest(body))
  end

  def acknowledge(envelope, effects, response) do
    with true <- exact?(response, ~w(state ack effects_digest results)),
         true <-
           response["state"] == "committed" and response["effects_digest"] == envelope["digest"],
         rows when is_list(rows) <- response["results"],
         true <- length(rows) == length(effects),
         true <-
           Enum.zip(rows, effects)
           |> Enum.all?(fn {row, effect} ->
             exact?(row, ~w(id status)) and row["id"] == effect.id and
               row["status"] in ~w(ok cancelled timeout failed) and
               (row["status"] == "ok" or effect.fallback != :fail)
           end) do
      results =
        Enum.zip(rows, effects)
        |> Enum.map(fn {row, effect} ->
          status = Enum.find(Result.statuses(), &(Atom.to_string(&1) == row["status"]))
          {:ok, result} = Result.new(effect.id, effect.owner, status)
          result
        end)

      {:ok, response["ack"], results}
    else
      _ -> {:error, "effects"}
    end
  end

  defp exact?(v, keys),
    do: is_map(v) and not is_struct(v) and Enum.sort(Map.keys(v)) == Enum.sort(keys)
end
