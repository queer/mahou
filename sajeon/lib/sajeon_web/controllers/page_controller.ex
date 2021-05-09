defmodule SajeonWeb.PageController do
  use SajeonWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
