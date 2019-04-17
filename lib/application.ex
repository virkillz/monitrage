defmodule Monitrage.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # import Supervisor.Spec

    children = [
      {Monitrage.start_link, []}
    ]

    opts = [strategy: :one_for_one, name: Monitrage.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
