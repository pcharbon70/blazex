defmodule BlazeX.Component.ActionView do
  @moduledoc "Explicit typed-action roots. Provider interfaces are runtime-owned; results are untrusted data requiring exact request correlation."
  alias BlazeX.Component.LocalView

  def start(supervisor, spec, ports, scheduler_policy, manifest, provider_port),
    do:
      LocalView.start(supervisor, spec, ports, scheduler_policy, %{
        manifest: manifest,
        port: provider_port
      })

  def result(supervisor, handle, result), do: LocalView.action_result(supervisor, handle, result)
end
