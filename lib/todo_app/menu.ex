defmodule TodoApp.Menu do
  @moduledoc """
    Menu that is shown when a user click on the taskbar icon of the TodoApp
  """
  import TodoWeb.Gettext
  use Desktop.Menu

  def handle_event(command, menu) do
    case command do
      <<"toggle:", id::binary>> ->
        TodoApp.Todo.toggle_todo(String.to_integer(id))

      <<"quit">> ->
        Desktop.Window.quit()

      <<"edit">> ->
        Desktop.Window.show(TodoWindow)
    end

    {:noreply, menu}
  end

  def mount(menu) do
    TodoApp.Todo.subscribe()
    {:ok, assign(menu, todos: TodoApp.Todo.all_todos())}
  end

  def handle_info(:changed, menu) do
    menu = assign(menu, todos: TodoApp.Todo.all_todos())

    if Enum.all?(menu.assigns.todos, &(Map.get(&1, :status) == "done")) do
      Menu.set_icon(menu, "icon32x32-done.png")
    else
      Menu.set_icon(menu, "icon32x32.png")
    end

    {:noreply, menu}
  end
end
