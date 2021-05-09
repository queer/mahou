defmodule Sajeon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      SajeonWeb.Telemetry,
      {Phoenix.PubSub, name: Sajeon.PubSub},
      SajeonWeb.Endpoint,1
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sajeon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SajeonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
