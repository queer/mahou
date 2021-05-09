defmodule Sample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SampleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sample.PubSub},
      # Start the Endpoint (http/https)
      SampleWeb.Endpoint
      # Start a worker by calling: Sample.Worker.start_link(arg)
      # {Sample.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
