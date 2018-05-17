defmodule YourApp.Controller do
  use Plug.Builder
  plug(:apply_action)

  def call(conn, action) do
    conn
    |> put_private(:action, action)
    |> super(nil)
  end

  def apply_action(conn, _opts) do
    apply(__MODULE__, conn.private.action, [conn])
  end

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
