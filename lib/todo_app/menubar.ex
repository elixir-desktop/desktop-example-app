defmodule TodoApp.MenuBar do
  import TodoWeb.Gettext
  use Desktop.Menu
  alias TodoApp.Todo
  alias Desktop.Window

  def handle_event(command, menu) do
    case command do
      <<"toggle:", id::binary>> ->
        Todo.toggle_todo(String.to_integer(id))

      <<"about">> ->
        Window.show_notification(TodoWindow, gettext("Sample Elixir Desktop App!"),
          callback: &TodoWeb.TodoLive.notification_event/1
        )

      <<"quit">> ->
        Window.quit()
    end

    {:noreply, menu}
  end

  def mount(menu) do
    TodoApp.Todo.subscribe()
    {:ok, assign(menu, todos: Todo.all_todos())}
  end

  def handle_info(:changed, menu) do
    {:noreply, assign(menu, todos: Todo.all_todos())}
  end
end
