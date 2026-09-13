defmodule BlazeXBrowserPhoenix.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BlazeX.Phoenix.BH01.FixtureAuthority,
      BlazeX.Phoenix.SessionRegistry,
      {BlazeX.Phoenix.CommandAdmission,
       declarations: %{
         "counter.increment" => %{
           schema: "counter.increment",
           payload: %{"amount" => {:integer, 1, 10}}
         }
       },
       grants: %{"operator" => ["counter.increment"], "viewer" => []}},
      BlazeX.Phoenix.CommandExecution,
      {Phoenix.PubSub, name: BlazeXBrowserPhoenix.PubSub},
      BlazeXBrowserPhoenix.StaticDeliveryCache,
      BlazeXBrowserPhoenix.Endpoint
    ]

    Supervisor.start_link(children,
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
