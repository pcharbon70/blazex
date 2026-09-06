defmodule BlazeX.Host.Browser.Lifecycle do
  @moduledoc """
  Closed Phase 4 vocabulary for independent roots sharing one browser runtime.

  Execution remains in the browser runtime package. This descriptor grants no
  runtime transport, shutdown, recovery, fallback, or renderer ownership.
  """

  @contract %{
    protocol: "blazex.root-lifecycle/1",
    max_roots_per_scope: 64,
    states: [
      :unregistered,
      :registered,
      :mounting,
      :ready,
      :moving,
      :disposing,
      :disposed,
      :failed
    ],
    operations: ["root.register", "root.mount", "root.update", "root.move", "root.dispose"],
    serialization: :one_fifo_queue_per_root,
    cross_root_progress: :independent,
    acknowledgement: [:root_id, :root_generation],
    runtime_owner: :runtime_registry,
    root_owns_runtime_release: false
  }

  @doc "Returns the immutable root lifecycle boundary descriptor."
  @spec contract() :: map()
  def contract, do: @contract
end
