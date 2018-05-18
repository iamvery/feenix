defmodule YourApp.Router do
  use Feenix.Router

  get "/cats", YourApp.Controller, :index
  get "/cats/felix", YourApp.Controller, :show

  # post "/cats"
  def do_match(conn, "POST", ["cats"]) do
    YourApp.Controller.create(conn)
  end
end
