defmodule YourApp.Router do
  use Feenix.Router

  # get "/cats"
  def do_match(conn, "GET", ["cats"]) do
    YourApp.Controller.call(conn, :index)
  end

  # get "/cats/felix"
  def do_match(conn, "GET", ["cats", "felix"]) do
    YourApp.Controller.call(conn, :show)
  end

  # post "/cats"
  def do_match(conn, "POST", ["cats"]) do
    YourApp.Controller.create(conn)
  end
end
