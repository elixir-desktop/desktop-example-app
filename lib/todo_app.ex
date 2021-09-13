defmodule TodoApp do
  use Application
  require Logger

  def config_dir() do
    Path.join([Desktop.OS.home(), ".config", "todo"])
  end

  @app Mix.Project.config()[:app]

  def start(:normal, []) do
    Desktop.identify_default_locale(TodoWeb.Gettext)
    File.mkdir_p!(config_dir())

    Application.put_env(:todo_app, TodoApp.Repo,
      database: Path.join(config_dir(), "/database.sq3")
    )

    {:ok, sup} = Supervisor.start_link([TodoApp.Repo], name: __MODULE__, strategy: :one_for_one)
    TodoApp.Repo.initialize()

    {:ok, _} = Supervisor.start_child(sup, TodoWeb.Sup)

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