Code.require_file("../../bh-04/support/reconciliation_cases.exs", __DIR__)

defmodule BlazeX.IncrementalRendererConformanceTest do
  use ExUnit.Case, async: true
  alias BlazeX.BH04.ReconciliationCases, as: Cases
  alias BlazeX.Renderer.{Context, Session}
  alias BlazeX.Renderer.DOM.Retained
  alias BlazeX.Renderer.DOM.ProtocolV2.IntentData
  alias BlazeX.Renderer.Headless

  for scenario <- Cases.scenarios() do
    @scenario scenario
    test "incremental/full-root/headless conformance: #{elem(scenario, 0)}" do
      row = Cases.execute(@scenario)
      assert row == Cases.execute(@scenario)
      {_name, _old, output, _stage} = @scenario

      if output do
        {:ok, headless} = Session.mount(Headless, output)
        {:ok, context} = Context.new(headless.owner, 0, :mount)
        {:ok, retained} = Retained.from_output(output, context)
        snapshot = headless.artifact.value

        assert tree_semantics(snapshot.tree) ==
                 Enum.map(retained.order, fn id ->
                   n = retained.nodes[id]

                   {id, Retained.values(n["attributes"])["data-bx-kind"], n["text"],
                    n["children"]}
                 end)

        listeners =
          Enum.flat_map(
            retained.order,
            &(IntentData.unpack(retained.nodes[&1]["listeners"]) || [])
          )

        assert Enum.sort(
                 Enum.map(snapshot.bindings, fn {:binding, event, owner, source} ->
                   {Atom.to_string(event), wire_identity(owner), wire_identity(source)}
                 end)
               ) ==
                 Enum.sort(Enum.map(listeners, &{&1["semantic"], &1["owner"], &1["source"]}))

        for {:focus, 1, owner, behavior, order, auto, restore, wrap} <- snapshot.focus do
          assert IntentData.unpack(retained.nodes[id(owner)]["focus"]) == %{
                   "behavior" => Atom.to_string(behavior),
                   "order" => optional(order),
                   "auto_focus" => auto,
                   "restore" => Atom.to_string(restore),
                   "wrap" => wrap
                 }
        end

        for {:selection, 1, owner, kind, value} <- snapshot.selections do
          assert IntentData.unpack(retained.nodes[id(owner)]["selection"]) == %{
                   "kind" => Atom.to_string(kind),
                   "value" => selection(value)
                 }
        end

        for {:accessibility, 1, owner, _role, name, description, _states, relationships, _live} <-
              snapshot.accessibility do
          attrs = Retained.values(retained.nodes[id(owner)]["attributes"])
          assert attrs["aria-label"] == optional(name)
          assert attrs["aria-description"] == optional(description)

          for {:relationship, kind, targets} <- relationships do
            name =
              %{
                labelled_by: "aria-labelledby",
                described_by: "aria-describedby",
                controls: "aria-controls",
                owns: "aria-owns",
                error_message: "aria-errormessage"
              }[kind]

            assert attrs[name] == Enum.map_join(targets, " ", &id/1)
          end
        end

        for {:layout, 1, owner, mode, _direction, _align, {:metric, :units, gap}, _padding,
             _width, _height, _minw, _minh, _maxw, _maxh, _grow, _overflow,
             _virtual} <- snapshot.layouts do
          attrs = Retained.values(retained.nodes[id(owner)]["attributes"])
          assert attrs["data-bx-layout-mode"] == Atom.to_string(mode)
          assert attrs["data-bx-layout-gap"] == "units:#{gap}"
        end
      else
        assert row["after"] == nil
      end
    end
  end

  defp tree_semantics({:node, 1, kind, owner, _key, text, children}),
    do: [
      {id(owner), Atom.to_string(kind), optional(text), Enum.map(children, &id(elem(&1, 3)))}
      | Enum.flat_map(children, &tree_semantics/1)
    ]

  defp optional(:none), do: nil
  defp optional({:some, value}), do: value

  defp portable({kind, values}) when kind in [:list, :tuple],
    do: %{"type" => Atom.to_string(kind), "value" => Enum.map(values, &portable/1)}

  defp portable({kind, value}), do: %{"type" => Atom.to_string(kind), "value" => value}

  defp wire_identity({:identity, root, path, generation}),
    do: %{
      "root" => portable(root),
      "path" => Enum.map(path, &portable/1),
      "generation" => generation
    }

  defp id(owner),
    do:
      "bx-" <>
        binary_part(
          Base.encode16(
            :crypto.hash(:sha256, :erlang.term_to_binary(wire_identity(owner), [:deterministic])),
            case: :lower
          ),
          0,
          24
        )

  defp selection(:none), do: nil
  defp selection({:single, value}), do: portable(value)
  defp selection({:multiple, values}), do: Enum.map(values, &portable/1)

  defp selection({:text_range, anchor, focus, direction}),
    do: %{"anchor" => anchor, "focus" => focus, "direction" => Atom.to_string(direction)}
end
