defmodule TodoWeb.TodoLive do
  use TodoWeb, :live_view

  @impl true

  def mount(_args, _session, socket) do
    todos = Model.Todos.all_todos()
    Model.Todos.subscribe()
    {:ok, assign(socket, todos: todos)}
  end

  @impl true
  def handle_info(:changed, socket) do
    todos = Model.Todos.all_todos()
    {:noreply, assign(socket, todos: todos)}
  end

  @impl true
  def handle_event("add", %{"text" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("add", %{"text" => text}, socket) do
    Model.Todos.add_todo(text, "todo")
    UI.show_notification("Added todo: #{text}")
    {:noreply, socket}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    Model.Todos.toggle_todo(id)
    {:noreply, socket}
  end

  def handle_event("drop", %{"id" => id}, socket) do
    id = String.to_integer(id)
    Model.Todos.drop_todo(id)
    {:noreply, socket}
  end
end
