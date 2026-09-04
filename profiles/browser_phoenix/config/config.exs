import Config

config :blazex_browser_phoenix,
  activation_state: :bh01_phase4,
  endpoint_state: :feasibility_static_delivery,
  runtime_state: :experimental

config :blazex_browser_phoenix, BlazeXBrowserPhoenix.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4101],
  server: false,
  secret_key_base: "bh01-feasibility-only-secret-key-base-not-for-production-000000000000"

import_config "#{config_env()}.exs"
