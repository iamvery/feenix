defmodule YourApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app

  plug(Plug.Logger)
  plug(YourApp.Router)
end
