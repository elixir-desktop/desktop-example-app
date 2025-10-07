defmodule Todo.MixProject do
  use Mix.Project

  @version "1.3.0"
  def project do
    [
      app: :todo_app,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [
        default_release: [
          applications: [runtime_tools: :permanent, ssl: :permanent],
          steps: [
            # &Desktop.Deployment.prepare_release/1,
            :assemble,
            &Desktop.Deployment.generate_installer/1
          ]
        ]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TodoApp, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :ssl,
        :crypto,
        :sasl,
        :tools,
        :inets | extra_applications(Mix.target())
      ]
    ]
  end

  def extra_applications(:host) do
    [:observer]
  end

  def extra_applications(_mobile) do
    []
  end

  defp aliases do
    [
      gettext: [
        "gettext.extract",
        "gettext.merge priv/gettext --locale de"
      ],
      "assets.deploy": [
        "phx.digest.clean --all",
        "esbuild default --minify",
        "sass default --no-source-map --style=compressed",
        "phx.digest"
      ],
      lint: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --ignore design"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    deps_list = [
      # {:desktop, path: "../desktop"},
      # {:desktop, "~> 1.5"},
      {:desktop, github: "elixir-desktop/desktop"},
      {:desktop_deployment, github: "elixir-desktop/deployment"},
      # {:desktop_deployment, path: "../deployment", runtime: false},

      # Phoenix
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sqlite3, "~> 0.22"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},

      # Assets
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:dart_sass, "~> 0.7", runtime: Mix.env() == :dev},

      # Credo
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]

    if Mix.target() in [:android, :ios] do
      deps_list ++ [{:wx, "~> 1.1", hex: :bridge, targets: [:android, :ios]}]
    else
      deps_list
    end
  end
end
