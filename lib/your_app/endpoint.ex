defmodule YourApp.Endpoint do
  use Feenix.Endpoint

  plug(Plug.Logger)
  plug(YourApp.Router)
end
