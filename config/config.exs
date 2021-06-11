# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :dde_iotserver_liveview,
  ecto_repos: [DdeIotserverLiveview.Repo]

# Configures the endpoint
config :dde_iotserver_liveview, DdeIotserverLiveviewWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ZTfRoyIA7RskUhonPuYHvy99v0hS2Gt/gaJ/MY4ORZA06zhis2SUYdkTSoJiXxGi",
  render_errors: [view: DdeIotserverLiveviewWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DdeIotserverLiveview.PubSub,
  live_view: [signing_salt: "nSSpTjO+"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
