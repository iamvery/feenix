defmodule YourApp.Router do
  use Plug.Builder

  plug(:match)

  def match(conn, _opts) do
    do_match(conn, conn.method, conn.path_info)
  end

  # get "/cats"
  def do_match(conn, "GET", ["cats"]) do
    YourApp.Controller.index(conn)
  end

  # get "/cats/felix"
  def do_match(conn, "GET", ["cats", "felix"]) do
    YourApp.Controller.show(conn)
  end

  # post "/cats"
  def do_match(conn, "POST", ["cats"]) do
    YourApp.Controller.create(conn)
  end
end
