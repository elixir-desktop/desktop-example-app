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
  @completed_log_topic "completed_tasks_log"

  def toggle_todo(id) do
    todo = Repo.get(__MODULE__, id)

    status =
      case todo.status do
        "todo" -> "done"
        "done" -> "todo"
      end

    if status == "done" do
      log_completed_task(todo.text)
    end

    change(todo, %{status: status})
    |> Repo.update()

    Phoenix.PubSub.broadcast(TodoApp.PubSub, @topic, :changed)
  end

  defp log_completed_task(text) do
    completed_at = DateTime.utc_now() |> DateTime.to_iso8601()

    Ecto.Adapters.SQL.query!(
      Repo,
      "INSERT INTO completed_tasks_log (text, completed_at) VALUES (?, ?)",
      [text, completed_at]
    )

    Phoenix.PubSub.broadcast(TodoApp.PubSub, @completed_log_topic, :completed_log_changed)
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
    order_by(__MODULE__, desc: :id)
    |> Repo.all()
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(TodoApp.PubSub, @topic)
  end

  def list_completed_log() do
    {:ok, result} =
      Ecto.Adapters.SQL.query(
        Repo,
        "SELECT id, text, completed_at FROM completed_tasks_log ORDER BY completed_at DESC",
        []
      )

    rows = result.rows || []

    Enum.map(rows, fn [id, text, completed_at] ->
      %{id: id, text: text, completed_at: completed_at}
    end)
  end

  def subscribe_completed_log() do
    Phoenix.PubSub.subscribe(TodoApp.PubSub, @completed_log_topic)
  end
end
