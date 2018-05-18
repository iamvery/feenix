defmodule YourApp.Router do
  use Feenix.Router

  get "/cats", YourApp.Controller, :index
  get "/cats/felix", YourApp.Controller, :show
  post "/cats", YourApp.Controller, :create
end
