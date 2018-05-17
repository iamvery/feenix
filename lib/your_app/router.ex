defmodule YourApp.Router do
  use Plug.Builder

  plug(:match)

  def match(conn, _opts) do
    do_match(conn, conn.method, conn.path_info)
  end

  # get "/cats"
  def do_match(conn, "GET", ["cats"]) do
    send_resp(conn, 200, "meows")
  end

  # get "/cats/felix"
  def do_match(conn, "GET", ["cats", "felix"]) do
    send_resp(conn, 200, "just meow")
  end

  # post "/cats"
  def do_match(conn, "POST", ["cats"]) do
    send_resp(conn, 201, "meow!")
  end
end
