import Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  backends: [:console]

config :logger, :console,
  level: :info,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id]

# Configures the endpoint
config :todo_app, TodoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 0],
  render_errors: [view: TodoWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: TodoApp.PubSub,
  live_view: [signing_salt: "sWpG9ljX"],
  secret_key_base: :crypto.strong_rand_bytes(32),
  server: true

config :phoenix, :json_library, Jason

config :todo_app,
  ecto_repos: [TodoApp.Repo]

# We're defining this at runtime
# config :todo_app, TodoApp.Repo, database: "~/.config/todo/database.sq3"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
