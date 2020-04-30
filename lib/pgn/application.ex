defmodule PGN.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      PGN.Repo,
      # Start the Telemetry supervisor
      PGNWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PGN.PubSub},
      # Start the Endpoint (http/https)
      PGNWeb.Endpoint
      # Start a worker by calling: PGN.Worker.start_link(arg)
      # {PGN.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PGN.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PGNWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
