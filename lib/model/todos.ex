defmodule Model.Todos do
  use Supervisor

  def start_link([]) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)

    query!("""
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY,
          text TEXT,
          status TEXT
        )
    """)

    {:ok, pid}
  end

  @topic "todos"
  def toggle_todo(id) do
    todo = Enum.find(all_todos(), fn todo -> todo.id == id end)

    status =
      case todo.status do
        "todo" -> "done"
        "done" -> "todo"
      end

    query!("UPDATE todos SET status = ?1 WHERE id = ?2", [status, id])
    Phoenix.PubSub.broadcast(Todo.PubSub, @topic, :changed)
  end

  def drop_todo(id) do
    query!("DELETE FROM todos WHERE id = ?1", [id])
    Phoenix.PubSub.broadcast(Todo.PubSub, @topic, :changed)
  end

  def add_todo(text, status) do
    query!("INSERT INTO todos (text, status) VALUES(?1, ?2)", [text, status])
    Phoenix.PubSub.broadcast(Todo.PubSub, @topic, :changed)
  end

  def all_todos() do
    query!("SELECT * FROM todos ORDER BY id ASC")
    |> Enum.map(&Map.new/1)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Todo.PubSub, @topic)
  end

  defp query!(sql, params \\ []) do
    {:ok, ret} = Sqlitex.Server.query(Todos, sql, bind: params)
    ret
  end

  def init(_args) do
    File.mkdir_p!(Todo.config_dir())
    default = Path.join(Todo.config_dir(), "database.sq3")
    name = Todos
    opts = [name: name, db_timeout: 30_000, stmt_cache_size: 50]

    children = [
      %{start: {Sqlitex.Server, :start_link, [to_charlist(default), opts]}, id: name}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
