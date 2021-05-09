defmodule PigWeb.Router do
  use PigWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PigWeb do
    pipe_through :api
  end
end
