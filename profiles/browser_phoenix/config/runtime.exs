import Config

if System.get_env("PHX_SERVER") do
  port = String.to_integer(System.get_env("PORT", "4101"))

  config :blazex_browser_phoenix, BlazeXBrowserPhoenix.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: port],
    server: true
end
