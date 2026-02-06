defmodule TodoApp.Repo do
  use Ecto.Repo, otp_app: :todo_app, adapter: Ecto.Adapters.SQLite3

  def initialize() do
    Ecto.Adapters.SQL.query!(__MODULE__, """
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY,
          text TEXT,
          status TEXT
        )
    """)

    Ecto.Adapters.SQL.query!(__MODULE__, """
        CREATE TABLE IF NOT EXISTS completed_tasks_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          completed_at TEXT NOT NULL
        )
    """)
  end
end
