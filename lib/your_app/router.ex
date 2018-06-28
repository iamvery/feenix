defmodule YourApp.Router do
  use Phoenix.Router

  get "/cats", YourApp.Controller, :index
  get "/cats/:name", YourApp.Controller, :show
  post "/cats", YourApp.Controller, :create
end
