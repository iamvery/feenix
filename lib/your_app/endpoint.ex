defmodule YourApp.Endpoint do
  def start_link do
    options = []
    Plug.Adapters.Cowboy.http(__MODULE__, options)
  end

  use Plug.Builder

  plug(:hello)
  plug(:world)

  def hello(conn, _opts) do
    put_private(conn, :name, "world")
  end

  def world(conn, _opts) do
    send_resp(conn, 200, "hello #{conn.private.name}")
  end
end
