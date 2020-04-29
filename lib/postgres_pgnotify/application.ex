defmodule PostgresPgnotify.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      PostgresPgnotify.Repo,
      # Start the Telemetry supervisor
      PostgresPgnotifyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PostgresPgnotify.PubSub},
      # Start the Endpoint (http/https)
      PostgresPgnotifyWeb.Endpoint
      # Start a worker by calling: PostgresPgnotify.Worker.start_link(arg)
      # {PostgresPgnotify.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PostgresPgnotify.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PostgresPgnotifyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
