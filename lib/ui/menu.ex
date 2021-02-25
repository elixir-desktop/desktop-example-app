defmodule UI.Menu do
  use Desktop.Menu

  def handle_event(command, menu) do
    case command do
      <<"toggle:", id::binary>> -> Model.Todos.toggle_todo(String.to_integer(id))
      <<"quit">> -> Desktop.Window.quit()
      <<"edit">> -> Desktop.Window.show(TodoWindow)
    end

    {:noreply, menu}
  end

  def mount(menu) do
    Model.Todos.subscribe()
    {:ok, assign(menu, todos: Model.Todos.all_todos())}
  end

  def handle_info(:changed, menu) do
    {:noreply, assign(menu, todos: Model.Todos.all_todos())}
  end
end
