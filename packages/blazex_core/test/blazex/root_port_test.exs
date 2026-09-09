defmodule BlazeX.RootPortTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.RootPort

  defmodule Root do
    use BlazeX.Component, role: :root, schema: [props: [], slots: []]
    def mount(_input), do: {:state, 0}
    def render(_input), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  def spec do
    %{
      root: "r",
      instance: "i",
      owner: "o",
      public_id: "root",
      component: Root,
      props: %{},
      slots: %{},
      capabilities: [],
      fallback: :none,
      timeout_ms: 1000
    }
  end

  test "start schema is normalized and infrastructure is not callback data" do
    assert {:ok, value} = RootPort.normalize(spec())
    assert value == spec()

    for invalid <- [
          Map.put(spec(), :pid, self()),
          %{spec() | props: %{bad: self()}},
          %{spec() | fallback: self()},
          %{spec() | timeout_ms: 0},
          %{spec() | instance: ""},
          %{spec() | component: String}
        ] do
      assert {:error, :invalid_start} == RootPort.normalize(invalid)
    end

    refute RootPort.ports?(%{})
  end

  test "correlation binds owner instance operation and every counter" do
    assert {:ok, correlation} = RootPort.correlation(spec(), 1, 1, 1, :mount)
    assert RootPort.correlation?(correlation)
    assert RootPort.acknowledgement?(%{correlation: correlation, result: :committed}, correlation)

    for field <- [
          :owner,
          :root,
          :instance,
          :generation,
          :revision,
          :sequence,
          :operation,
          :transaction
        ] do
      refute RootPort.acknowledgement?(
               %{correlation: Map.put(correlation, field, nil), result: :committed},
               correlation
             )
    end

    refute RootPort.correlation?(%{correlation | sequence: 9_007_199_254_740_992})
    refute RootPort.acknowledgement?(%{correlation: correlation, result: :ready}, correlation)
  end

  test "candidate and redacted summary detect drift and hide private token and state" do
    {:ok, correlation} = RootPort.correlation(spec(), 1, 1, 1, :mount)
    digest = String.duplicate("a", 64)
    assert {:ok, value} = RootPort.candidate(correlation, %{count: 1}, digest, self())
    assert RootPort.candidate?(value, correlation)
    refute RootPort.candidate?(%{value | state: %{count: 2}}, correlation)
    refute RootPort.candidate?(%{value | final_digest: digest}, correlation)

    assert Map.keys(RootPort.summary(value)) |> Enum.sort() == [
             :correlation,
             :final_digest,
             :output_digest,
             :state_digest
           ]

    assert {:error, :semantic_rejected} = RootPort.candidate(correlation, self(), digest, nil)
    assert RootPort.failure({:private, "secret"}) == :port_failed
  end
end
