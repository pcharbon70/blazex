defmodule BlazeX.Component.RecoveryView do
  @moduledoc "Explicit opt-in root failure boundary; policy and ports remain runtime-owned."
  alias BlazeX.Component.LocalView

  def start(supervisor, spec, ports, schedule, recovery, actions \\ nil),
    do: LocalView.start(supervisor, spec, ports, schedule, actions, recovery)

  def retry(supervisor, handle, generation, fingerprint, source, spec),
    do:
      LocalView.retry(supervisor, handle, %{
        generation: generation,
        fingerprint: fingerprint,
        source: source,
        spec: spec
      })
end
