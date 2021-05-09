defmodule AgmaWeb.Router do
  use AgmaWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AgmaWeb do
    pipe_through :api

    scope "/v1" do
      post "/create", ContainerController, :create
      post "/status", ContainerController, :change_status
    end
  end
end
