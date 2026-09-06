defmodule BlazeX.Host.Browser.Lifecycle do
  @moduledoc """
  Closed Phase 5 vocabulary for independent roots sharing one browser runtime.

  Execution remains in the browser runtime package. This descriptor grants no
  runtime transport, fallback presentation, or renderer ownership.
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
    root_owns_runtime_release: false,
    runtime_states: [:starting, :ready, :stopping, :stopped, :recovering, :failed, :fallback],
    shutdown: %{
      protocol: "blazex.runtime-shutdown/1",
      operation: "runtime.shutdown",
      acknowledgement: [:scope_id, :runtime_generation],
      default_timeout_ms: 5_000,
      max_timeout_ms: 10_000,
      release: :registry_owned_exactly_once,
      terminal_record: :stopped_tombstone
    },
    runtime_loss: %{
      protocol: "blazex.runtime-loss/1",
      acknowledgement: [:scope_id, :runtime_generation],
      stale_report: :reject_without_mutation,
      max_replacements: 1,
      replacement_delay_ms: 100,
      root_replay: :same_handles_all_or_nothing
    },
    fallback: %{
      protocol: "blazex.runtime-fallback/1",
      presentation: :non_dom_decision_only,
      partial_activation: false,
      classes: %{
        "identity-mismatch" => "deployment-action",
        "unsupported-prerequisite" => "static-content",
        "runtime-startup" => "user-action",
        "runtime-loss" => "user-action",
        "recovery-exhausted" => "user-action"
      }
    }
  }

  @doc "Returns the immutable root and runtime lifecycle boundary descriptor."
  @spec contract() :: map()
  def contract, do: @contract
end
