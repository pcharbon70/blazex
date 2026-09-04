defmodule BlazeXBrowserPhoenix.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([BlazeXBrowserPhoenix.Endpoint],
      strategy: :one_for_one,
      name: BlazeXBrowserPhoenix.Supervisor
    )
  end

  @impl true
  def config_change(changed, removed, _extra) do
    BlazeXBrowserPhoenix.Endpoint.config_change(changed, removed)
    :ok
  end
end
