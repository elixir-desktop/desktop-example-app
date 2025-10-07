import Config

config :esbuild,
  version: "0.25.4",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2022  --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :dart_sass,
  version: "1.61.0",
  default: [
    args: ~w(css/app.scss ../priv/static/assets/css/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: false,
  backends: [:console]

config :logger, :console,
  level: :notice,
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id]

# Configures the endpoint
config :todo_app, TodoWeb.Endpoint,
  # url: [host: "localhost", port: 10_000 + :rand.uniform(45_000)],
  # because of the iOS rebind - this is now a fixed port, but randomly selected
  http: [ip: {127, 0, 0, 1}, port: 10_000 + :rand.uniform(45_000)],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TodoWeb.ErrorHTML, json: TodoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TodoApp.PubSub,
  live_view: [signing_salt: "sWpG9ljX"],
  secret_key_base: :crypto.strong_rand_bytes(64),
  server: true

config :phoenix, :json_library, Jason

config :todo_app,
  ecto_repos: [TodoApp.Repo]

# We're defining this at runtime
# config :todo_app, TodoApp.Repo, database: "~/.config/todo/database.sq3"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
