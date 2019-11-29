defmodule MorpionElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      MorpionElixir.Morpion,
      MorpionElixir.WorkerSupervisor,
      {MorpionElixir.Conductor, 5}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MorpionElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
