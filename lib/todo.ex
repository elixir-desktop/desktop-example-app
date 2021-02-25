defmodule Todo do
  use Application
  require Logger

  def config_dir() do
    Path.join([Desktop.OS.home(), ".config", "todo"])
  end

  @app Mix.Project.config()[:app]
  def resource_path(filename) do
    Path.join(:code.priv_dir(@app), filename)
  end

  def start(:normal, []) do
    window = {
      Desktop.Window,
      [
        app: @app,
        id: TodoWindow,
        title: "Todos",
        size: {600, 500},
        icon: "icon.png",
        menubar: UI.MenuBar,
        icon_menu: UI.Menu,
        url: fn -> TodoWeb.Router.Helpers.live_url(TodoWeb.Endpoint, TodoWeb.TodoLive) end
      ]
    }

    children = [Model.Todos, TodoWeb.Sup, window]
    Supervisor.start_link(children, name: __MODULE__, strategy: :one_for_one)
  end

  def config_change(changed, _new, removed) do
    TodoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
