defmodule UI.Menu do
  require EEx
  use GenServer

  def handle_click(_item, command) do
    List.to_string(command)
    |> case do
      <<"toggle:", id::binary>> -> Model.Todos.toggle_todo(String.to_integer(id))
      <<"quit">> -> UI.quit()
      <<"edit">> -> UI.show()
    end
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Model.Todos.subscribe()
    Process.register(spawn_link(&connector/0), :connector)

    dom =
      menu(todos: Model.Todos.all_todos())
      |> :erlsom.simple_form()

    {:ok, dom}
  end

  # Persistent helper worker that is the "reference" for all :wx events.
  # If the worker would be short-lived :wx would drop the events as soon as the
  # worker stops.
  # To avoid deadlocks it's not the GenServer filling this role but this
  # independent worker
  defp connector() do
    receive do
      fun -> fun.()
    end

    connector()
  end

  def handle_info(:changed, _m) do
    dom =
      menu(todos: Model.Todos.all_todos())
      |> :erlsom.simple_form()

    {:noreply, dom}
  end

  def handle_call(:dom, _from, dom) do
    {:reply, dom, dom}
  end

  def create_menu() do
    UI.wx_set_env()
    {:ok, {'menu', [], dom}, _rest} = GenServer.call(__MODULE__, :dom)

    :wx.batch(fn ->
      menu = :wxMenu.new()
      do_create_menu([menu], dom)
      menu
    end)
  end

  defp do_create_menu(menues, dom) when is_list(dom) do
    dom = OS.invert_menu(dom)

    Enum.each(dom, fn e ->
      do_create_menu(menues, e)
    end)
  end

  defp do_create_menu(menues, dom) when is_tuple(dom) do
    case dom do
      {'hr', _attr, _content} ->
        :wxMenu.appendSeparator(hd(menues))

      {'item', attr, content} ->
        attr = Map.new(attr)

        kind =
          case attr['type'] do
            'checkbox' -> Wx.wxITEM_CHECK()
            'separator' -> Wx.wxITEM_SEPARATOR()
            'radio' -> Wx.wxITEM_RADIO()
            _other -> Wx.wxITEM_NORMAL()
          end

        item = :wxMenuItem.new(id: Wx.wxID_ANY(), text: List.flatten(content), kind: kind)
        id = :wxMenuItem.getId(item)
        :wxMenu.append(hd(menues), item)

        if attr['checked'] != nil do
          :wxMenuItem.check(item, check: is_true(attr['checked']))
        end

        if attr['onclick'] != nil do
          event_src = if OS.windows?(), do: List.last(menues), else: hd(menues)

          # This is called from a callback, so instead we do event registration
          # from the persistent "connector" worker to keep the hooks alive.
          send(:connector, fn ->
            UI.wx_set_env()

            :wxMenu.connect(
              event_src,
              :command_menu_selected,
              callback: fn _, _ ->
                handle_click(item, attr['onclick'])
              end,
              id: id
            )
          end)
        end

        if is_true(attr['disabled']) do
          :wxMenu.enable(hd(menues), id, false)
        end

      {'menu', attr, content} ->
        attr = Map.new(attr)
        menu = :wxMenu.new()
        do_create_menu([menu | menues], content)
        :wxMenu.append(hd(menues), Wx.wxID_ANY(), attr['label'] || '', menu)
    end
  end

  def is_true(value) do
    value != nil and value != 'false' and value != '0'
  end

  def escape(string) do
    :erlsom_lib.xmlString(string)
  end

  EEx.function_from_file(:defp, :menu, "lib/ui/menu.eex", [:assigns])
end
