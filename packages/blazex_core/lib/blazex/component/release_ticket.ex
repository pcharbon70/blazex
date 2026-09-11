defmodule BlazeX.Component.ReleaseTicket do
  @moduledoc false
  alias BlazeX.Component.{Input, Schema}

  @maximum_bytes 4096
  @forbidden ~w(owner path generation capability selection acquisition resource credentials credential password secret access_token authorization authentication socket pid process function callback)

  def maximum_bytes, do: @maximum_bytes

  def new(provider, id, token) do
    ticket = %{version: 1, provider: provider, id: id, token: token}
    if valid?(ticket), do: {:ok, ticket}, else: {:error, :invalid_release_ticket}
  end

  def valid?(ticket) do
    keys?(ticket, [:version, :provider, :id, :token]) and ticket.version == 1 and
      Schema.name?(ticket.provider) and Schema.name?(ticket.id) and
      Input.portable?(ticket.token) and safe?(ticket.token) and
      byte_size(:erlang.term_to_binary(ticket)) <= @maximum_bytes
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  def page?(tickets, maximum) do
    is_list(tickets) and tickets != [] and length(tickets) <= maximum and
      Enum.all?(tickets, &valid?/1) and
      tickets |> Enum.map(& &1.id) |> then(&(Enum.uniq(&1) == &1))
  rescue
    _ -> false
  end

  defp safe?(value) when is_map(value) do
    not is_struct(value) and
      Enum.all?(value, fn {key, child} ->
        safe_key?(key) and safe?(child)
      end)
  end

  defp safe?(value) when is_list(value), do: Enum.all?(value, &safe?/1)
  defp safe?(value) when is_tuple(value), do: value |> Tuple.to_list() |> Enum.all?(&safe?/1)
  defp safe?(_), do: true

  defp safe_key?(key) when is_atom(key) or is_binary(key), do: to_string(key) not in @forbidden
  defp safe_key?(key), do: is_number(key)

  defp keys?(value, keys),
    do: is_map(value) and not is_struct(value) and Enum.sort(Map.keys(value)) == Enum.sort(keys)
end
