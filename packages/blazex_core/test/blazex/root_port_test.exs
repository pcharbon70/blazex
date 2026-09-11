defmodule BlazeX.RootPortTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{NestedTable, RootPort}

  defmodule Root do
    use BlazeX.Component, role: :root, schema: [props: [], slots: []]
    def mount(_input), do: {:state, 0}
    def render(_input), do: {:output, {:semantic, 1, %{kind: :group}}}
  end

  defmodule PreparedPagePort do
    def release_prepared_ticket_page(result, _tickets), do: result
  end

  defmodule EnvelopePagePort do
    def release_ticket_page(observer, tickets) do
      send(observer, {:release_envelopes, tickets})
      List.duplicate(:released, length(tickets))
    end
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

  test "portable digests are independent of map construction order" do
    left = Map.new([{:second, %{value: 2}}, {:first, [1, 2]}])
    right = Map.new([{:first, [1, 2]}, {:second, %{value: 2}}])

    assert NestedTable.digest(left) == NestedTable.digest(right)
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

    assert {:error, :semantic_rejected} =
             RootPort.candidate(correlation, %{}, String.duplicate("A", 64), nil)

    assert {:error, :semantic_rejected} =
             RootPort.candidate(correlation, %{}, String.duplicate("g", 64), nil)

    assert Map.keys(RootPort.summary(value)) |> Enum.sort() == [
             :correlation,
             :final_digest,
             :output_digest,
             :state_digest
           ]

    assert {:error, :semantic_rejected} = RootPort.candidate(correlation, self(), digest, nil)
    assert RootPort.failure({:private, "secret"}) == :port_failed
  end

  test "prepared ticket pages preserve only provider-authorized scalar success" do
    tickets = [{"one", "provider", 1}, {"two", "provider", 2}]

    assert :released =
             RootPort.release_prepared_ticket_page({PreparedPagePort, :released}, tickets)

    assert [:released, {:error, :lost}] =
             RootPort.release_prepared_ticket_page(
               {PreparedPagePort, [:released, {:error, :lost}]},
               tickets
             )

    for malformed <- [:lost, {:error, :lost}, [:released]] do
      assert [{:error, :port_failed}, {:error, :port_failed}] =
               RootPort.release_prepared_ticket_page({PreparedPagePort, malformed}, tickets)
    end
  end

  test "public ticket page compatibility receives envelope maps" do
    tickets = [{"one", "provider", 1}, {"two", "provider", 2}]

    assert [:released, :released] =
             RootPort.release_prepared_ticket_page({EnvelopePagePort, self()}, tickets)

    assert_receive {:release_envelopes, envelopes}
    assert Enum.all?(envelopes, &is_map/1)
    assert Enum.map(envelopes, & &1.id) == ["one", "two"]
    assert Enum.all?(envelopes, &(&1.version == 1 and &1.provider == "provider"))
  end
end
