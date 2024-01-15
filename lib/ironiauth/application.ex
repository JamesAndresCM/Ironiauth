defmodule Ironiauth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      IroniauthWeb.Telemetry,
      # Start the Ecto repository
      Ironiauth.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ironiauth.PubSub},
      # Start Finch
      {Finch, name: Ironiauth.Finch},
      # Start the Endpoint (http/https)
      IroniauthWeb.Endpoint
      # Start a worker by calling: Ironiauth.Worker.start_link(arg)
      # {Ironiauth.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ironiauth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IroniauthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
