defmodule SampleWeb.PageController do
  use SampleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
