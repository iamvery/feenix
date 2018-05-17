defmodule YourApp.Controller do
  use Feenix.Controller

  plug(:assigns_kitty_count)

  def index(conn) do
    send_resp(conn, 200, "#{conn.assigns.count} meows")
  end

  def show(conn) do
    send_resp(conn, 200, "just meow")
  end

  def create(conn) do
    send_resp(conn, 201, "meow!")
  end

  defp assigns_kitty_count(conn, _opts) do
    assign(conn, :count, 42)
  end
end
