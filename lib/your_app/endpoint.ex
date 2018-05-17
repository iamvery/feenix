defmodule YourApp.Endpoint do
  def start_link do
    options = []
    Plug.Adapters.Cowboy.http(__MODULE__, options)
  end

  use Plug.Builder

  plug(Plug.Logger)
  plug(YourApp.Router)
end
