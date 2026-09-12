defmodule BlazeXBrowserPhoenix.StaticDeliveryCache do
  @moduledoc false
  use GenServer

  alias BlazeX.Phoenix.StaticDelivery

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(options, :name, __MODULE__))
  end

  def fetch(root, attestation_path, server \\ __MODULE__) do
    root = Path.expand(root)
    attestation_path = Path.expand(attestation_path)

    with {:ok, manifest_bytes} <- File.read(Path.join(root, "build-manifest.json")),
         {:ok, attestation_bytes} <- File.read(attestation_path) do
      identity =
        {root, attestation_path, :crypto.hash(:sha256, manifest_bytes),
         :crypto.hash(:sha256, attestation_bytes)}

      GenServer.call(
        server,
        {:fetch, identity, root, manifest_bytes, attestation_bytes},
        30_000
      )
    end
  end

  def snapshot(server \\ __MODULE__), do: GenServer.call(server, :snapshot)
  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  @impl true
  def init(:ok), do: {:ok, %{identity: nil, result: nil, validations: 0, hits: 0}}

  @impl true
  def handle_call(
        {:fetch, identity, _root, _manifest, _attestation},
        _from,
        %{identity: identity} = state
      ) do
    {:reply, state.result, %{state | hits: state.hits + 1}}
  end

  def handle_call({:fetch, identity, root, manifest_bytes, attestation_bytes}, _from, state) do
    reply =
      with {:ok, manifest} <- Jason.decode(manifest_bytes),
           {:ok, attestation} <- Jason.decode(attestation_bytes) do
        {:ok, StaticDelivery.new!(root, manifest, attestation, manifest_bytes)}
      end

    {:reply, reply,
     %{
       state
       | identity: identity,
         result: reply,
         validations: state.validations + 1
     }}
  rescue
    ArgumentError ->
      result = {:error, :attestation_invalid}

      {:reply, result,
       %{state | identity: identity, result: result, validations: state.validations + 1}}
  end

  def handle_call(:snapshot, _from, state) do
    {:reply, Map.take(state, [:validations, :hits]), state}
  end

  def handle_call(:reset, _from, _state) do
    state = %{identity: nil, result: nil, validations: 0, hits: 0}
    {:reply, :ok, state}
  end
end
