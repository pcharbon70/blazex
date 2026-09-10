defmodule BlazeX.BH05.Conformance.Item do
  use BlazeX.Component,
    role: :stateful,
    context: ["locale"],
    schema: [
      props: [
        {"label", [type: :string, required: true]},
        {"selected", [type: :boolean, default: false]}
      ],
      slots: [{"default", [key: :optional, max: 1]}]
    ]

  def init(_), do: {:state, 0}
  def update(_), do: :no_change
  def handle_event(%{state: {:present, value}}), do: advance(value + 1)
  def handle_info(_), do: :no_change
  def render(%{state: {:present, value}}), do: output(value)
  def replace(_), do: {:state, 0}
  def dispose(_), do: :ok

  defp advance(value), do: {:state, value}

  defp output(value),
    do: {:output, {:semantic, 1, %{kind: :text, content: Integer.to_string(value)}}}
end

defmodule BlazeX.BH05.Conformance.Root do
  use BlazeX.Component,
    role: :root,
    capabilities: ["ui.storage"],
    registry: ["item"],
    context: ["locale"],
    schema: [
      props: [{"title", [type: :string, required: true]}],
      slots: [{"default", [key: :optional, max: 16]}]
    ]

  def mount(_), do: {:state, 0}
  def update(_), do: :no_change
  def handle_event(%{state: {:present, value}}), do: {:state, value + 1}
  def handle_info(_), do: :no_change
  def effect_result(_), do: :no_change

  def render(%{state: {:present, value}}),
    do:
      {:output,
       {:semantic, 1,
        %{
          kind: :group,
          children: [%{kind: :text, content: Integer.to_string(value)}],
          bindings: [:activate],
          accessibility: %{role: :group, name: "Conformance"}
        }}}

  def terminate(_), do: :ok
end

defmodule BlazeX.BH05.Conformance.Fault do
  use BlazeX.Component, role: :root, schema: [props: [], slots: []]
  def mount(_), do: {:state, 0}
  def update(_), do: {:error, :injected}
  def handle_event(_), do: {:error, :injected}
  def handle_info(_), do: {:error, :injected}
  def render(_), do: {:error, :injected}
  def terminate(_), do: :ok
end
