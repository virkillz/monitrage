defmodule Monitrage.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # import Supervisor.Spec

    children = [
      # {Registry, keys: :duplicate, name: :monitrage_registry},
      {Monitrage.Scanner, []}
    ]

    opts = [strategy: :one_for_one, name: Monitrage.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
