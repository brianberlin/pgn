# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :postgres_pgnotify,
  ecto_repos: [PostgresPgnotify.Repo]

# Configures the endpoint
config :postgres_pgnotify, PostgresPgnotifyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Cr6x6ztICQQxtVKWzTDyY4l2AR+ZQlseEOdOZsl/9ZfkVDhlsth7nQ/4vLj/ZFmj",
  render_errors: [view: PostgresPgnotifyWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PostgresPgnotify.PubSub,
  live_view: [signing_salt: "yJZ0KRDp"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
