defmodule BlazeX.BH05.Label do
  use BlazeX.Component, role: :pure, props: ["text"]

  def render(%{props: %{text: text}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: text}}}
end

defmodule BlazeX.BH05.Counter do
  use BlazeX.Component, role: :stateful
  def init(_input), do: {:state, 0}
  def update(_input), do: :no_change
  def handle_event(%{state: {:present, count}}), do: {:state, count + 1}
  def handle_info(_input), do: :no_change

  def render(%{state: {:present, count}}),
    do: {:output, {:semantic, 1, %{kind: :text, content: Integer.to_string(count)}}}

  def replace(_input), do: {:state, 0}
  def dispose(_input), do: :ok
end

defmodule BlazeX.BH05.Root do
  use BlazeX.Component, role: :root, capabilities: ["clock"], registry: ["tick"]
  def mount(_input), do: {:state, %{}}
  def update(_input), do: :no_change
  def handle_event(_input), do: {:actions, %{}, [{:timer, "tick", %{delay_ms: 10}}]}
  def handle_info(_input), do: :no_change
  def render(_input), do: {:output, {:semantic, 1, %{kind: :group, children: []}}}
  def commit_ack(_input), do: :no_change
  def effect_result(_input), do: :no_change
  def failure(_input), do: {:retry_request, :transient}
  def retry(_input), do: {:state, %{}}
  def replace(_input), do: {:state, %{}}
  def terminate(_input), do: :ok
end
