defmodule YourApp do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      #supervisor(YourApp.Endpoint, []),
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: YourApp.Supervisor)
  end
end
