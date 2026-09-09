defmodule BlazeX.Component.ActionManifest do
  @moduledoc "Closed static public action declarations for runtime admission, BH-06 reachability and future BH-07 command registration."
  alias BlazeX.Component.{Action, Schema}
  @common [:schema_version, :request, :result, :error]

  def validate(value) do
    valid =
      Action.keys?(value, [:effects, :commands, :owners]) and Action.public?(value) and
        Action.size?(value, 262_144) and
        declarations?(value.effects, :effect) and declarations?(value.commands, :command) and
        is_map(value.owners) and map_size(value.owners) in 1..128 and
        Enum.all?(value.owners, fn {id, grant} ->
          Schema.name?(id) and
            Action.keys?(grant, [:effects, :commands, :transfers]) and
            names?(grant.effects, Map.keys(value.effects)) and
            names?(grant.commands, Map.keys(value.commands)) and
            names?(grant.transfers, [:self, :child, :parent, :root])
        end)

    if valid, do: :ok, else: {:error, :invalid_manifest}
  rescue
    _ -> {:error, :invalid_manifest}
  end

  def metadata(manifest) do
    with :ok <- validate(manifest) do
      {:ok,
       %{
         version: 1,
         effects: manifest.effects,
         commands: manifest.commands,
         owners: manifest.owners,
         command_trust: :untrusted_client,
         server_requirements: [
           :authentication,
           :authorization,
           :validation,
           :idempotency,
           :audit,
           :result_normalization
         ]
       }}
    end
  end

  def declaration(manifest, action, component, spec) do
    kind = if action.kind == :command, do: :commands, else: :effects

    with grant when is_map(grant) <- Map.get(manifest.owners, component.public_id),
         true <- action.body.declaration in Map.fetch!(grant, kind),
         declaration when is_map(declaration) <-
           get_in(manifest, [kind, action.body.declaration]),
         true <-
           kind == :commands or
             (declaration.capability in spec.capabilities and
                action.body.fallback == declaration.fallback),
         {:ok, payload} <-
           Schema.normalize(declaration.request, action.body.payload, %{
             kind: :host,
             root: spec.root,
             owner: spec.root
           }),
         true <- Action.public?(payload) do
      {:ok, declaration, %{action | body: %{action.body | payload: payload}}}
    else
      _ -> {:error, :unauthorized_action}
    end
  end

  defp declarations?(value, kind),
    do:
      is_map(value) and map_size(value) <= 32 and
        Enum.all?(value, fn {id, declaration} ->
          keys =
            @common ++
              if(kind == :effect,
                do: [:capability, :operation, :fallback, :lease_kind, :lease_limit],
                else: []
              )

          Schema.name?(id) and Action.keys?(declaration, keys) and
            declaration.schema_version == "1.0.0" and
            Enum.all?(
              [declaration.request, declaration.result, declaration.error],
              &Schema.host?/1
            ) and
            (kind == :command or
               (Schema.name?(declaration.capability) and Schema.name?(declaration.operation) and
                  declaration.fallback in [:deny, :omit, :component] and
                  is_integer(declaration.lease_limit) and declaration.lease_limit in 0..16 and
                  if(declaration.lease_limit == 0,
                    do: declaration.lease_kind == nil,
                    else: Schema.name?(declaration.lease_kind)
                  )))
        end)

  defp names?(values, allowed),
    do:
      is_list(values) and length(values) <= length(allowed) and Enum.uniq(values) == values and
        Enum.all?(values, &(&1 in allowed))
end
