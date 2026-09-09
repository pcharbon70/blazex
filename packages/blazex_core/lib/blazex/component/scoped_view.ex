defmodule BlazeX.Component.ScopedView do
  @moduledoc "Explicit scoped-root update ingress; registry/provider configuration stays runtime-owned."
  alias BlazeX.Component.{Action, LocalView, RootSchedule}

  def select(supervisor, handle, generation, revision, registry_generation, selection),
    do:
      LocalView.enqueue(supervisor, handle, %{
        scope_version: 1,
        root: handle.root,
        generation: generation,
        revision: revision,
        registry_generation: registry_generation,
        selection: selection
      })

  def change(supervisor, handle, generation, revision, providers),
    do:
      LocalView.enqueue(supervisor, handle, %{
        scope_version: 1,
        root: handle.root,
        generation: generation,
        revision: revision,
        providers: providers
      })

  def followups(port, candidate) do
    if function_exported?(elem(port, 0), :scope_followups, 2) do
      work = BlazeX.Component.RootPort.call(port, :scope_followups, [candidate])
      true = is_list(work) and length(work) <= 128
      true = Enum.all?(work, &valid_work?(&1, candidate))
      {:ok, work}
    else
      {:ok, []}
    end
  rescue
    _ -> {:error, :invalid_scope_work}
  end

  def valid_work?(work, accepted),
    do:
      is_map(work) and
        work.kind in [:scope_change, :scope_invalidation] and work.class == :message and
        work.route == :self and work.source == work.target and work.target.path == [] and
        work.origin == :scope and work.timer == :none and work.supersedable == false and
        Action.public?(work.payload) and Action.size?(work.payload, 65_536) and
        RootSchedule.valid_dispatch?(work, accepted)
end
