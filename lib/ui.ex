defmodule UI do
  use GenServer

  @enforce_keys [:frame]
  defstruct [
    :bar,
    :frame,
    :notification,
    :webview
  ]

  def start_link([]) do
    {_ref, _num, _type, pid} = :wx_object.start_link({:local, __MODULE__}, __MODULE__, [], [])
    {:ok, pid}
  end

  def init(options) do
    :persistent_term.put(:wx, :wx.new(options))
    :persistent_term.put(:wx_env, :wx.get_env())

    frame =
      :wxFrame.new(wx(), Wx.wxID_ANY(), "Todos", [
        {:size, {600, 500}},
        {:style, Wx.wxDEFAULT_FRAME_STYLE()}
      ])

    :wxFrame.connect(frame, :close_window, [
      {:callback,
       fn _, _ ->
         :wxFrame.hide(frame)
       end}
    ])

    # This simple version will not show right on MacOS:
    # icon = :wxIcon.new(Todo.resource_path("icon.png"))
    # This does show right though:
    image = :wxImage.new(Todo.resource_path("icon.png"))
    bitmap = :wxBitmap.new(image)
    icon = :wxIcon.new()
    :wxIcon.copyFromBitmap(icon, bitmap)
    :wxBitmap.destroy(bitmap)

    :wxTopLevelWindow.setIcon(frame, icon)
    sizer = :wxBoxSizer.new(Wx.wxHORIZONTAL())
    webview = :wxWebView.new(frame, -1)
    :wxBoxSizer.add(sizer, webview, proportion: 1, flag: Wx.wxEXPAND())
    :wxFrame.setSizer(frame, sizer)

    # MacOS osMenu
    if OS.type() == MacOS do
      :wxMenu.connect(:wxMenuBar.oSXGetAppleMenu(:wxMenuBar.new()), :command_menu_selected)
    end

    bar = :wxTaskBarIcon.new(createPopupMenu: &UI.Menu.create_menu/0)
    true = :wxTaskBarIcon.setIcon(bar, icon, [{:tooltip, "Todos"}])

    notification = :wxNotificationMessage.new("Todos", flags: Wx.wxICON_INFORMATION())

    ui = %UI{
      frame: frame,
      webview: webview,
      bar: bar,
      notification: notification
    }

    show()
    {frame, ui}
  end

  def show() do
    url =
      TodoWeb.Router.Helpers.live_url(TodoWeb.Endpoint, TodoWeb.TodoLive) <>
        "?k=" <> TodoWeb.Auth.login_key()

    :io.format("Open: ~s~n", [url])
    GenServer.cast(__MODULE__, {:show, url})
  end

  def show_notification(text) do
    GenServer.cast(__MODULE__, {:show_notification, text})
  end

  def quit() do
    OS.shutdown()
  end

  def handle_cast({:show_notification, message}, ui = %UI{notification: notification}) do
    :wxNotificationMessage.setMessage(notification, to_charlist(message))
    :wxNotificationMessage.show(notification)
    {:noreply, ui}
  end

  def handle_cast({:show, url}, ui = %UI{webview: webview, frame: frame}) do
    :wxWebView.loadURL(webview, url)
    :wxWindow.show(frame, show: true)
    :wxTopLevelWindow.centerOnScreen(frame)
    OS.raise_frame(frame)
    {:noreply, ui}
  end

  def wx_env() do
    :persistent_term.get(:wx_env)
  end

  def wx_set_env() do
    :wx.set_env(wx_env())
    wx()
  end

  defp wx() do
    :persistent_term.get(:wx)
  end
end
