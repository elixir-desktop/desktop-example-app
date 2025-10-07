defmodule TodoWeb.PageController do
  use TodoWeb, :controller

  def home(conn, _params) do
    render(conn, :todo)
  end
end
