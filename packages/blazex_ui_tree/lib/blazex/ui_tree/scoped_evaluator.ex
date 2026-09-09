defmodule BlazeX.UITree.ScopedEvaluator do
  @moduledoc "Opt-in scoped context evaluator over existing root commit and reconciliation contracts."
  alias BlazeX.UITree.{RootEvaluator, ScopedPlan}

  def prepare(config, request, prior) do
    if request.operation in [:mount, :replace],
      do: RootEvaluator.prepare(config, request, prior),
      else: {:error, :scheduled_scope_required}
  end

  def prepare_scheduled(config, request, prior),
    do: RootEvaluator.prepare_scheduled(config, request, prior)

  def admit(config, work, prior), do: RootEvaluator.admit(config, work, prior)

  def admit_action(config, action, candidate),
    do: RootEvaluator.admit_action(config, action, candidate)

  def cleanup(config, candidate, reason), do: RootEvaluator.cleanup(config, candidate, reason)
  def cleanup_removed(config, prior, next), do: RootEvaluator.cleanup_removed(config, prior, next)
  def scope_ingress(config, payload, accepted), do: ScopedPlan.ingress(config, payload, accepted)
  def scope_followups(_, candidate), do: ScopedPlan.followups(candidate)
end
