defmodule Todo.MixProject do
  use Mix.Project

  @version "0.0.1"
  def project do
    [
      app: :todo_app,
      version: @version,
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
      mod: {TodoApp, []},
      extra_applications: [:logger, :ssl, :crypto, :sasl, :tools, :inets | extra()]
    ]
  end

  def extra() do
    if System.get_env("MOBILE") do
      []
    else
      [:observer]
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.5"},
      {:ecto_sql, "~> 3.5"},
      {:ecto_sqlite3, "~> 0.5.2"},
      {:desktop, github: "elixir-desktop/desktop"}
      # {:desktop, path: "../desktop"}
    ]
  end
end
