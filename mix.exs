defmodule Todo.MixProject do
  use Mix.Project

  def project do
    [
      app: :todo,
      version: "0.0.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Todo, []},
      extra_applications: [:logger, :wx, :ssl, :crypto, :sasl, :tools, :inets, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sqlitex, github: "diodechain/sqlitex"},
      {:erlsom, "~> 1.5"},

      # phoenix stuff
      {:phoenix, "~> 1.5.7"},
      {:phoenix_live_view, "~> 0.15"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:plug_crypto, github: "elixir-plug/plug_crypto", override: true},
      {:jason, "~> 1.0"}
    ]
  end
end
