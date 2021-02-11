defmodule Todo do
  use Application
  require Logger

  def config_dir() do
    Path.join([OS.home(), ".config", "todo"])
  end

  @app Mix.Project.config()[:app]
  def resource_path(filename) do
    Path.join(:code.priv_dir(@app), filename)
  end

  def start(:normal, []) do
    children = [Model.Todos, TodoWeb.Sup, UI.Menu, UI]
    Supervisor.start_link(children, name: __MODULE__, strategy: :one_for_one)
  end

  def config_change(changed, _new, removed) do
    TodoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
