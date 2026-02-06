defmodule TodoWeb.TodoLive do
  @moduledoc """
    Main live view of our TodoApp. Just allows adding, removing and checking off
    todo items
  """
  use TodoWeb, :live_view

  @impl true

  def render(assigns) do
    ~H"""
    <div class="header">
      <h2>{gettext "My Todo List"}</h2>
      <span class="header-actions">
        <button type="button" class="icon-btn" phx-click="show_log" title={gettext "Completed tasks log"}>
          &#128203;
        </button>
      </span>
      <form phx-submit="add" id="add-todo-form" action="#">
        <input
          type="text"
          name="text"
          placeholder={gettext "Add new todo item..."}
          value={@form_text}
          phx-change="update_form"
        />
        <button type="submit">&#8617;</button>
      </form>
    </div>

    <%= if @view == :list do %>
      <ul>
        <%= for item <- @todos do %>
          <li phx-click="toggle" phx-value-id={item.id} class={item.status}>
            {item.text}
            <span id={"close-#{item.id}"} class="close" phx-click="drop" phx-value-id={item.id}>&#215;</span>
          </li>
        <% end %>
      </ul>
    <% else %>
      <div class="log-view">
        <button type="button" class="back-btn" phx-click="show_list">&#8592; {gettext "Back to list"}</button>
        <h3>{gettext "Completed tasks log"}</h3>
        <ul class="log-list">
          <%= for %{date_label: date_label, entries: entries} <- @completed_log_grouped do %>
            <li class="log-day-separator">{date_label}</li>
            <%= for entry <- entries do %>
              <li class="log-entry">
                <span class="log-text">{entry.text}</span>
                <span class="log-date">{format_completed_at(entry.completed_at)}</span>
              </li>
            <% end %>
          <% end %>
        </ul>
      </div>
    <% end %>
    """
  end

  @impl true

  def mount(_args, _session, socket) do
    todos = TodoApp.Todo.all_todos()
    TodoApp.Todo.subscribe()
    TodoApp.Todo.subscribe_completed_log()

    {:ok,
     socket
     |> assign(todos: todos)
     |> assign(form_text: "")
     |> assign(view: :list)
     |> assign(completed_log: [])
     |> assign(completed_log_grouped: [])}
  end

  @impl true
  def handle_info(:changed, socket) do
    todos = TodoApp.Todo.all_todos()
    {:noreply, assign(socket, todos: todos)}
  end

  def handle_info(:completed_log_changed, socket) do
    log = if socket.assigns.view == :log, do: TodoApp.Todo.list_completed_log(), else: []
    grouped = group_log_by_day(log)
    {:noreply, assign(socket, completed_log: log, completed_log_grouped: grouped)}
  end

  @impl true
  def handle_event("update_form", %{"text" => text}, socket) do
    {:noreply, assign(socket, form_text: text)}
  end

  def handle_event("add", %{"text" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("add", %{"text" => text}, socket) do
    TodoApp.Todo.add_todo(text, "todo")

    Desktop.Window.show_notification(TodoWindow, "Added todo: #{text}",
      callback: &notification_event/1
    )

    {:noreply, assign(socket, form_text: "")}
  end

  def handle_event("show_log", _params, socket) do
    log = TodoApp.Todo.list_completed_log()
    grouped = group_log_by_day(log)

    {:noreply,
     socket
     |> assign(view: :log)
     |> assign(completed_log: log)
     |> assign(completed_log_grouped: grouped)}
  end

  def handle_event("show_list", _params, socket) do
    {:noreply, assign(socket, view: :list)}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    TodoApp.Todo.toggle_todo(id)
    {:noreply, socket}
  end

  def handle_event("drop", %{"id" => id}, socket) do
    id = String.to_integer(id)
    TodoApp.Todo.drop_todo(id)
    {:noreply, socket}
  end

  def notification_event(action) do
    Desktop.Window.show_notification(TodoWindow, "You did '#{inspect(action)}' me!",
      id: :click,
      type: :warning
    )
  end

  defp group_log_by_day(entries) do
    now = DateTime.utc_now()
    today = Date.new!(now.year, now.month, now.day)

    entries
    |> Enum.group_by(&date_from_completed_at(&1.completed_at), & &1)
    |> Enum.sort_by(fn {date, _} -> date || ~D[1970-01-01] end, &>=/2)
    |> Enum.map(fn {date, list} ->
      %{date_label: date_label(date, today), entries: list}
    end)
  end

  defp date_from_completed_at(nil), do: nil

  defp date_from_completed_at(iso8601) when is_binary(iso8601) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, dt, _} -> Date.new!(dt.year, dt.month, dt.day)
      _ -> nil
    end
  end

  defp date_label(nil, _today), do: gettext("Other")

  defp date_label(date, today) do
    cond do
      date == today -> gettext("Today")
      date == Date.add(today, -1) -> gettext("Yesterday")
      true -> "#{date.year}-#{pad(date.month)}-#{pad(date.day)}"
    end
  end

  defp format_completed_at(nil), do: ""

  defp format_completed_at(iso8601) when is_binary(iso8601) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, dt, _} ->
        "#{dt.year}-#{pad(dt.month)}-#{pad(dt.day)} #{pad(dt.hour)}:#{pad(dt.minute)}"

      _ ->
        iso8601
    end
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
