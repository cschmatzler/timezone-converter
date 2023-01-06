defmodule TimezoneConverter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TimezoneConverterWeb.Telemetry,
      # Start the Ecto repository
      TimezoneConverter.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TimezoneConverter.PubSub},
      # Start Finch
      {Finch, name: TimezoneConverter.Finch},
      # Start the Endpoint (http/https)
      TimezoneConverterWeb.Endpoint
      # Start a worker by calling: TimezoneConverter.Worker.start_link(arg)
      # {TimezoneConverter.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TimezoneConverter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TimezoneConverterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
