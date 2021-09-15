defmodule TodoApp.Menu do
  @moduledoc """
    Menu that is shown when a user click on the taskbar icon of the TodoApp
  """
  import TodoWeb.Gettext
  use Desktop.Menu

  def handle_event(command, menu) do
    case command do
      <<"toggle:", id::binary>> -> TodoApp.Todo.toggle_todo(String.to_integer(id))
      <<"quit">> -> Desktop.Window.quit()
      <<"edit">> -> Desktop.Window.show(TodoWindow)
    end

    {:noreply, menu}
  end

  def mount(menu) do
    TodoApp.Todo.subscribe()
    {:ok, assign(menu, todos: TodoApp.Todo.all_todos())}
  end

  def handle_info(:changed, menu) do
    {:noreply, assign(menu, todos: TodoApp.Todo.all_todos())}
  end
end
