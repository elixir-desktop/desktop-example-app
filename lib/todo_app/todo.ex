defmodule TodoApp.Todo do
  @moduledoc """
    Repo for our TodoApp. Minimal data structure for a todo item.
  """
  use Ecto.Schema
  alias TodoApp.Repo
  alias __MODULE__
  import Ecto.Changeset
  import Ecto.Query, only: [order_by: 2]

  schema "todos" do
    field(:text, :string)
    field(:status, :string)
  end

  @topic "todos"
  def toggle_todo(id) do
    todo = Repo.get(__MODULE__, id)

    status =
      case todo.status do
        "todo" -> "done"
        "done" -> "todo"
      end

    change(todo, %{status: status})
    |> Repo.update()

    Phoenix.PubSub.broadcast(TodoApp.PubSub, @topic, :changed)
  end

  def drop_todo(id) do
    Repo.get(__MODULE__, id)
    |> Repo.delete()

    Phoenix.PubSub.broadcast(TodoApp.PubSub, @topic, :changed)
  end

  def add_todo(text, status) do
    %Todo{text: text, status: status}
    |> Repo.insert()

    Phoenix.PubSub.broadcast(TodoApp.PubSub, @topic, :changed)
  end

  def all_todos() do
    order_by(__MODULE__, asc: :id)
    |> Repo.all()
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(TodoApp.PubSub, @topic)
  end
end
