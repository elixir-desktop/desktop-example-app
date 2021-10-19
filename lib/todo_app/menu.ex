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
    menu = assign(menu, todos: TodoApp.Todo.all_todos())
    set_state_icon(menu)
    {:ok, menu}
  end

  def handle_info(:changed, menu) do
    menu = assign(menu, todos: TodoApp.Todo.all_todos())

    set_state_icon(menu)

    {:noreply, menu}
  end

  defp set_state_icon(menu) do
    if checked?(menu.todos) do
      Menu.set_icon(menu, {:file, "icon32x32-done.png"})
    else
      Menu.set_icon(menu, {:file, "icon32x32.png"})
    end
  end

  defp checked?([]) do
    true
  end

  defp checked?([%{status: "done"} | todos]) do
    checked?(todos)
  end

  defp checked?([%{status: _} | todos]) do
    false && checked?(todos)
  end
end
