defmodule BlazeX.Component.ScheduledView do
  @moduledoc "Opt-in typed scheduling over a LocalView root. Handles remain identity-only; producer grants belong to static runtime policy."
  alias BlazeX.Component.LocalView
  def start(supervisor, spec, ports, policy), do: LocalView.start(supervisor, spec, ports, policy)
  def enqueue(supervisor, handle, envelope), do: LocalView.enqueue(supervisor, handle, envelope)
  def runtime_loss(supervisor, handle), do: LocalView.runtime_loss(supervisor, handle)

  for class <- [:event, :update, :message, :timer] do
    def unquote(class)(supervisor, handle, %{class: unquote(class)} = envelope),
      do: enqueue(supervisor, handle, envelope)

    def unquote(class)(_, _, _), do: {:error, :invalid_ingress}
  end
end

defmodule BlazeX.Component.SchedulingPort do
  @moduledoc "Outward read-only binding admission and scheduled evaluation; never exposes adapters to callback modules."
  @callback admit(term(), map(), map()) :: :ok | {:error, atom()}
  @callback prepare_scheduled(term(), map(), map()) :: {:ok, map(), list()} | {:error, atom()}
  @callback cleanup_removed(term(), map(), map()) :: :ok | {:error, atom()}

  def supported?({module, _}),
    do:
      Code.ensure_loaded?(module) and
        Enum.all?([admit: 3, prepare_scheduled: 3, cleanup_removed: 3], fn {name, arity} ->
          function_exported?(module, name, arity)
        end)

  def supported?(_), do: false
end
