defmodule YourApp.Controller do
  use Phoenix.Controller

  plug(Feenix.Params)
  plug(:assigns_kitty_count)

  def index(conn, _params) do
    send_resp(conn, 200, "#{conn.assigns.count} meows")
  end

  def show(conn, %{"name" => name}) do
    send_resp(conn, 200, "#{name} meow")
  end

  def create(conn, %{"name" => name}) do
    send_resp(conn, 201, "#{name} meow!")
  end

  defp assigns_kitty_count(conn, _opts) do
    assign(conn, :count, 42)
  end
end
