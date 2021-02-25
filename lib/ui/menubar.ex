defmodule UI.MenuBar do
  use Desktop.Menu
  alias Model.Todos
  alias Desktop.Window

  def handle_event(command, menu) do
    case command do
      <<"toggle:", id::binary>> ->
        Todos.toggle_todo(String.to_integer(id))

      <<"about">> ->
        Window.show_notification(TodoWindow, "Sample Elixir Desktop App!",
          callback: &TodoWeb.TodoLive.notification_event/1
        )

      <<"quit">> ->
        Window.quit()
    end

    {:noreply, menu}
  end

  def mount(menu) do
    Model.Todos.subscribe()
    {:ok, assign(menu, todos: Todos.all_todos())}
  end

  def handle_info(:changed, menu) do
    {:noreply, assign(menu, todos: Todos.all_todos())}
  end
end
