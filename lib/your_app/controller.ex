defmodule YourApp.Controller do
  use Feenix.Controller

  def index(conn) do
    send_resp(conn, 200, "meows")
  end

  def show(conn) do
    send_resp(conn, 200, "just meow")
  end

  def create(conn) do
    send_resp(conn, 201, "meow!")
  end
end
