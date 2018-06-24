defmodule Feenix.Params do
  use Plug.Builder

  plug(:fetch_query_params)
end
