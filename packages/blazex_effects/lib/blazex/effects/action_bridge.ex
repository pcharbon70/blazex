defmodule BlazeX.Effects.ActionBridge do
  @moduledoc "Outward adapter from typed component requests to declared capability contracts and future command doubles. No concrete host or server transport."
  @behaviour BlazeX.Component.ActionPort
  alias BlazeX.Component.{ReleaseTicket, RootPort}
  alias BlazeX.Core.Identity
  alias BlazeX.Effects.{Capability, Effect, Negotiation, Resource}

  @impl true
  def select(config, %{kind: :effect_request, id: id, declaration: declaration}) do
    capability = Enum.find(Capability.names(), &(Atom.to_string(&1) == declaration.capability))

    operation =
      Enum.find(
        Map.get(Capability.operations(), capability, []),
        &(Atom.to_string(&1) == declaration.operation)
      )

    binding = Map.get(config.bindings, id, %{primary: nil, fallback: nil})
    fallback = %{deny: :fail, omit: :omit, component: :component}[declaration.fallback]
    requirement = if fallback == :fail, do: :required, else: :optional

    with true <- operation != nil,
         {:ok, needed} <- Capability.new(capability, requirement, fallback),
         {:ok, result} <- Negotiation.negotiate([needed], config.grants) do
      cond do
        capability in result.granted and Map.has_key?(config.providers, binding.primary) ->
          {:granted, binding.primary}

        capability in result.fallbacks and Map.has_key?(config.providers, binding.fallback) ->
          {:fallback, binding.fallback}

        true ->
          :denied
      end
    else
      _ -> :denied
    end
  end

  def select(config, %{kind: :command, id: id}) do
    case Map.get(config.commands, id) do
      name when is_binary(name) ->
        if Map.has_key?(config.providers, name), do: {:granted, name}, else: :denied

      _ ->
        :denied
    end
  end

  def select(_, _), do: :denied

  @impl true
  def submit(config, entry), do: invoke(config, entry.selection.name, :submit, packet(entry))
  @impl true
  def cancel(config, entry), do: invoke(config, entry.selection.name, :cancel, packet(entry))
  @impl true
  def release(config, lease) do
    invoke(config, lease.selection.name, :release, release_packet(lease))
  end

  @impl true
  def prepare_release(config, lease) do
    provider = lease.selection.name

    case invoke(config, provider, :prepare_release, release_packet(lease)) do
      {:ok, token} -> {:ok, %{provider: provider, token: token}}
      _ -> {:error, :unavailable}
    end
  end

  @impl true
  def release_ticket(config, ticket) do
    if ReleaseTicket.valid?(ticket),
      do: invoke(config, ticket.provider, :release_prepared, ticket.token),
      else: {:error, :invalid_release_ticket}
  end

  @impl true
  def release_ticket_page(config, tickets), do: Enum.map(tickets, &release_ticket(config, &1))

  defp release_packet(lease) do
    capability = Enum.find(Capability.names(), &(Atom.to_string(&1) == lease.capability))
    {:ok, resource} = Resource.new(struct(Identity, lease.owner), capability, lease.id)

    %{
      resource: resource,
      acquisition: lease.acquisition,
      kind: lease.kind
    }
  end

  def release_page(config, leases), do: Enum.map(leases, &release(config, &1))

  def command_record(entry) do
    body = entry.action.body

    %{
      version: 1,
      trust: :untrusted_client,
      declaration: body.declaration,
      schema_version: entry.declaration.schema_version,
      payload: body.payload,
      correlation: entry.correlation,
      idempotency_key: body.idempotency_key,
      timeout_ms: body.timeout_ms,
      optimistic_revision: body.optimistic_revision,
      expected_result: entry.declaration.result,
      expected_error: entry.declaration.error,
      server_requirements: [
        :authentication,
        :authorization,
        :validation,
        :idempotency,
        :audit,
        :result_normalization
      ]
    }
  end

  defp packet(%{action: %{kind: :command}} = entry), do: command_record(entry)

  defp packet(entry) do
    capability =
      Enum.find(Capability.names(), &(Atom.to_string(&1) == entry.declaration.capability))

    operation =
      Enum.find(
        Map.get(Capability.operations(), capability, []),
        &(Atom.to_string(&1) == entry.declaration.operation)
      )

    {:ok, effect} =
      Effect.new(
        entry.action.id,
        struct(Identity, entry.action.owner),
        capability,
        operation,
        entry.action.body.payload,
        timeout_ms: entry.action.body.timeout_ms,
        fallback: %{deny: :fail, omit: :omit, component: :component}[entry.action.body.fallback]
      )

    %{
      effect: effect,
      correlation: entry.correlation,
      idempotency_key: entry.action.body.idempotency_key
    }
  end

  defp invoke(config, name, callback, value) do
    case Map.get(config.providers, name) do
      {module, private} -> RootPort.call({module, private}, callback, [value])
      _ -> {:error, :unavailable}
    end
  end
end
