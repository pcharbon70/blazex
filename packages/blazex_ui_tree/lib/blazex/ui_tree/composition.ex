defmodule BlazeX.UITree.Composition do
  @moduledoc """
  Bounded, atomic pure composition of a trusted build-authored invocation graph.

  `evaluate/6` plans the complete graph before rendering and returns
  `{:ok, %{output: intent_set, trace: events, output_digest: hash, trace_digest: hash}}`
  (also carrying `contract`), or `{:error, diagnostic}` with no candidate output.
  Records contain exactly `module`, `public_id`, `site`, `key`, `props`, `slots`
  and ordered `children` references. All modules use the schema-aware pure facade.

  Candidate maps contain `kind`, optional text `content`, a list of semantic
  `bindings`, and optional `layout`, `accessibility`, `focus`, `selection` maps.
  Intent maps use their public constructor's option names plus `mode`, `role`,
  `behavior`, or `kind` respectively; selection also accepts `value`.
  Accessibility relationship targets are derived identity paths, not identities.
  `required_capabilities` must be a subset of the component's declarations.

  No retained state, effects, renderer calls or process isolation. Components are
  trusted build code subject to dependency audit, not sandboxed arbitrary Elixir.
  Digests use the portable canonical encoding shared by the component kernel.
  """
  alias BlazeX.Component.NestedTable
  alias BlazeX.UITree.{CompositionPlan, PureCandidates, SemanticAcceptance}
  @contract "0.1.0-bh05-pure-composition"

  def evaluate(root, generation, reference, graph, boundary, capabilities \\ []) do
    try do
      plan = CompositionPlan.build(root, generation, reference, graph, boundary, capabilities)
      {candidate, trace} = PureCandidates.evaluate(plan)
      {output, accepted} = SemanticAcceptance.accept(candidate)
      output_digest = digest(output)
      trace = trace ++ accepted ++ [%{event: :final_output, digest: output_digest}]

      {:ok,
       %{
         contract: @contract,
         output: output,
         output_digest: output_digest,
         trace: trace,
         trace_digest: digest(trace)
       }}
    rescue
      _ -> failure(:malformed_input, [])
    catch
      :throw, {:composition_error, code, path} -> failure(code, path)
      _, _ -> failure(:malformed_input, [])
    end
  end

  defp failure(code, path) do
    event =
      if code in [:callback_failed, :callback_rejected], do: code, else: :composition_rejected

    trace = [%{event: event, code: code, path: path}]

    {:error,
     %{contract: @contract, code: code, path: path, trace: trace, trace_digest: digest(trace)}}
  end

  defp digest(value), do: NestedTable.digest(value)
end
