defmodule TodoWeb.Error do
  use TodoWeb, :remote_controller

  def index(conn, _opts) do
    send_resp(conn, 401, "Unauthorized")
  end
end
