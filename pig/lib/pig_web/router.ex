defmodule PigWeb.Router do
  use PigWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PigWeb do
    pipe_through :api

    get "/deploys", ApiController, :deploys
    get "/ports", ApiController, :external_ports
  end
end
