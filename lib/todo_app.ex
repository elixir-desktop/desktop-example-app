defmodule TodoApp do
  @moduledoc """
    TodoApp Application. This module takes care of the the boot.
    Because the TodoApp is a standalone desktop application there is
    initial Database initialization needed when the SQlite database is
    not yet existing. This is done during start() by
    calling `TodoApp.Repo.initialize()`.

    Other than that this module initialized the main `Desktop.Window`
    and configures it to create a taskbar icon as well.

  """
  use Application
  require Logger

  def config_dir() do
    Path.join([Desktop.OS.home(), ".config", "todo"])
  end

  @app Mix.Project.config()[:app]

  def start(:normal, []) do
    Desktop.identify_default_locale(TodoWeb.Gettext)
    File.mkdir_p!(config_dir())

    # TODO: move to runtime.exs
    Application.put_env(:todo_app, TodoApp.Repo,
      database: Path.join(config_dir(), "/database.sq3")
    )

    :ets.new(:session, [:named_table, :public, read_concurrency: true])

    {:ok, sup} =
      Supervisor.start_link(
        [
          TodoWeb.Telemetry,
          TodoApp.Repo,
          {DNSCluster, query: Application.get_env(:todo, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: TodoApp.PubSub},
          # Start a worker by calling: Todo.Worker.start_link(arg)
          # {Todo.Worker, arg},
          # Start to serve requests, typically the last entry
          TodoWeb.Endpoint
        ],
        name: __MODULE__,
        strategy: :one_for_one
      )

    TodoApp.Repo.initialize()

    {:ok, _} =
      Supervisor.start_child(sup, {
        Desktop.Window,
        [
          app: @app,
          id: TodoWindow,
          title: "TodoApp",
          size: {600, 500},
          icon: "icon.png",
          menubar: TodoApp.MenuBar,
          icon_menu: TodoApp.Menu,
          url: &TodoWeb.Endpoint.url/0
        ]
      })
  end

  def config_change(changed, _new, removed) do
    TodoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
