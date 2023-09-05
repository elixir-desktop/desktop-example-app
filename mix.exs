defmodule Todo.MixProject do
  use Mix.Project

  @version "1.1.0"
  def project do
    [
      app: :todo_app,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TodoApp, []},
      extra_applications: [
        :logger,
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
      {:ecto_sqlite3, "~> 0.8"},
      {:exqlite, github: "elixir-desktop/exqlite", override: true},
      # {:desktop, path: "../desktop"},
      {:desktop, "~> 1.5"},
      {:desktop_deployment, github: "elixir-desktop/deployment"},
      # {:desktop_deployment, path: "../deployment", runtime: false},

      # Phoenix
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.18"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.4", only: [:dev]},
      {:gettext, "~> 0.22"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},

      # Assets
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:dart_sass, "~> 0.5", runtime: Mix.env() == :dev},

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
