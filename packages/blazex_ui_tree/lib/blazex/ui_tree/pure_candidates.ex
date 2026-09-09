defmodule BlazeX.UITree.PureCandidates do
  @moduledoc false
  alias BlazeX.Component.Result
  alias BlazeX.UITree.CompositionPlan

  def evaluate(plan) do
    enter = %{event: :invocation_enter, component: plan.public_id, path: plan.path}

    trace =
      if plan.slot,
        do: [%{event: :slot_expansion, component: plan.public_id, path: plan.path}, enter],
        else: [enter]

    output = if plan.data, do: plan.data, else: render(plan)
    {children, traces} = Enum.map(plan.children, &evaluate/1) |> Enum.unzip()

    candidate = %{
      identity: plan.identity,
      output: output,
      children: children,
      path: plan.path,
      public_id: plan.public_id,
      capabilities: if(plan.input, do: plan.input.capabilities, else: [])
    }

    {candidate,
     trace ++
       List.flatten(traces) ++
       [%{event: :invocation_exit, component: plan.public_id, path: plan.path}]}
  end

  defp render(plan) do
    result =
      try do
        plan.module.render(plan.input)
      rescue
        _ -> CompositionPlan.fail(:callback_failed, plan.path)
      catch
        _, _ -> CompositionPlan.fail(:callback_failed, plan.path)
      end

    case result do
      {:rejected, _} ->
        CompositionPlan.fail(:callback_rejected, plan.path)

      {:output, {:semantic, 1, output}} ->
        CompositionPlan.require!(
          Result.validate(:pure, :render, result) == :ok,
          :invalid_result,
          plan.path
        )

        output

      _ ->
        CompositionPlan.fail(:invalid_result, plan.path)
    end
  end
end
