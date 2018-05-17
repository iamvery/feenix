defmodule YourApp.Endpoint do
  use Plug.Builder

  plug(:hello)
  plug(:world)

  def hello(conn, _opts) do
    IO.puts("hello")
    conn
  end

  def world(conn, _opts) do
    IO.puts("world")
    conn
  end
end
