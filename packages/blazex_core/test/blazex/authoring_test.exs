defmodule BlazeX.AuthoringTest do
  use ExUnit.Case, async: false
  alias BlazeX.Component.{Input, Result}

  defmodule Label do
    use BlazeX.Component, role: :pure, props: ["text"]

    def render(%{props: %{text: text}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: text}}}
  end

  defmodule Counter do
    use BlazeX.Component, role: :stateful
    def init(_input), do: {:state, 0}

    def render(%{state: {:present, value}}),
      do: {:output, {:semantic, 1, %{kind: :text, content: value}}}

    def handle_event(_input), do: :no_change
  end

  defmodule Root do
    use BlazeX.Component, role: :root, capabilities: ["clock"], registry: ["tick"]
    def mount(_input), do: {:state, %{}}
    def render(_input), do: {:output, {:semantic, 1, %{kind: :group, children: []}}}
    def retry(_input), do: {:retry_request, :transient}
  end

  defp input(role \\ :pure, transition \\ :render) do
    root = %{root: "demo", path: [], generation: 1}

    %{
      role: role,
      transition: transition,
      props: %{},
      slots: %{},
      state: :absent,
      payload: :absent,
      root: root,
      identity: root,
      generation: 1,
      revision: 0,
      sequence: 0,
      capabilities: [],
      context_keys: []
    }
  end

  test "literal metadata is exact and deterministic" do
    assert Label.__blazex_component__() == %{
             version: "0.1.0-bh05-candidate",
             role: :pure,
             visibility: :public_candidate,
             implementation: :private,
             callbacks: [render: 1],
             required: [:render],
             optional: [],
             declarations: %{
               props: ["text"],
               slots: [],
               capabilities: [],
               registry: [],
               context: []
             }
           }

    assert Counter.__blazex_component__().callbacks == [handle_event: 1, init: 1, render: 1]
    assert Root.__blazex_component__().role == :root
    assert Root.__blazex_component__() == Root.__blazex_component__()
  end

  test "all role and callback input shapes" do
    for role <- BlazeX.Component.Contract.roles() do
      %{required: required, optional: optional} = BlazeX.Component.Contract.callbacks(role)

      for callback <- required ++ optional do
        value = input(role, callback)
        value = if role == :stateful, do: put_in(value.identity.path, ["child"]), else: value

        value =
          if role != :pure and callback not in [:init, :mount],
            do: %{value | state: {:present, nil}},
            else: value

        value =
          if callback in [
               :handle_event,
               :handle_info,
               :commit_ack,
               :effect_result,
               :failure,
               :retry,
               :dispose,
               :terminate
             ],
             do: %{value | payload: {:present, %{}}},
             else: value

        assert Input.validate(value) == :ok
      end
    end
  end

  test "input availability, identity and internal value rejection" do
    for bad <- [
          Map.put(input(), :host, %{}),
          %{input() | generation: 2},
          %{input() | revision: -1},
          %{input() | sequence: 9_007_199_254_740_992},
          %{input() | state: {:present, %{}}},
          %{input() | payload: {:present, %{}}},
          %{input() | props: %{nested: %{socket: "hidden"}}},
          %{input() | slots: %{f: fn -> :ok end}},
          %{input() | props: %{p: self()}},
          %{input() | context_keys: ["secret", "a"]},
          %{input() | root: %{}},
          %{input() | role: :root, transition: :init},
          %{},
          nil
        ] do
      assert Input.validate(bad) ==
               {:error, %{code: :invalid_input, contract: "0.1.0-bh05-candidate"}}
    end
  end

  test "closed result forms validate without invoking callbacks" do
    for {role, callback, result} <- [
          {:pure, :render, {:output, {:semantic, 1, %{kind: :text}}}},
          {:stateful, :init, {:state, nil}},
          {:root, :mount, {:state, %{}}},
          {:root, :update, :no_change},
          {:root, :handle_event, {:actions, 1, [{:effect, "load", %{}}]}},
          {:stateful, :handle_info, {:stop, :normal}},
          {:root, :failure, {:retry_request, :transient}},
          {:root, :terminate, :ok},
          {:stateful, :dispose, :ok},
          {:pure, :render, {:rejected, :failed}}
        ] do
      assert Result.validate(role, callback, result) == :ok
    end

    assert Label.render(%{input() | props: %{text: "Hello"}}) ==
             {:output, {:semantic, 1, %{kind: :text, content: "Hello"}}}
  end

  test "malformed ambiguous opaque excessive and role-inappropriate results are redacted" do
    for bad <- [
          {:ok, 1},
          {:state, self()},
          {:state, make_ref()},
          {:state, %RuntimeError{message: "SECRET"}},
          {:state, [1 | 2]},
          {:state, 1, %{output: %{}}},
          {:actions, 0, []},
          {:actions, 0, [{:dom, "x", %{}}]},
          {:actions, 0, [{:effect, "x", %{host: "SECRET"}}]},
          {:actions, 0, List.duplicate({:effect, "x", %{}}, 129)},
          {:rejected, "SECRET"},
          {:retry_request, :transient},
          {:output, {:semantic, 1, %{}}}
        ] do
      assert Result.validate(:stateful, :update, bad) ==
               {:error, %{code: :invalid_result, contract: "0.1.0-bh05-candidate"}}
    end

    assert Result.validate(
             :root,
             :handle_event,
             {:actions, 0, List.duplicate({:message, "x", nil}, 128)}
           ) == :ok

    assert {:error, _} = Result.validate(:pure, :render, {:output, {:semantic, 2, %{}}})
    assert {:error, _} = Result.validate(:pure, :render, {:output, {:semantic, 1, %{dom: %{}}}})
  end

  test "invalid declarations and callback exports fail compilation with fixed diagnostics" do
    for {options, body, reason} <- [
          {"role: :pure, role: :root", "", :invalid_declaration},
          {"role: :other", "", :invalid_declaration},
          {"role: :pure, render_mode: :server", "", :invalid_declaration},
          {"role: :pure, props: [\"b\", \"a\"]", "", :invalid_declaration},
          {"role: :pure", "", :missing_callback},
          {"role: :pure", "def render(_, _), do: :ok", :missing_callback},
          {"role: :pure", "def render(_), do: :ok; def state_has_changed(), do: :ok",
           :unexpected_export},
          {"role: :pure", "use BlazeX.Component, role: :root", :invalid_declaration},
          {"role: :pure", "def render(_), do: BlazeX.Core.Evaluator.mount(nil,nil,nil)",
           :forbidden_dependency},
          {"role: :pure", "def render(_), do: Process.self()", :forbidden_dependency},
          {"role: :pure", "def render(_), do: :erlang.make_ref()", :forbidden_dependency},
          {"role: :pure", "def render(i), do: apply(i.module, :render, [i])",
           :forbidden_dependency},
          {"role: :pure", "def render(i), do: i.fun.(i)", :forbidden_dependency}
        ] do
      name = "BlazeX.InvalidAuthoring#{System.unique_integer([:positive])}"
      source = "defmodule #{name} do use BlazeX.Component, #{options}; #{body} end"

      assert_raise CompileError, "BH-05 authoring: #{reason}", fn ->
        Code.compile_string(source)
      end
    end
  end
end
