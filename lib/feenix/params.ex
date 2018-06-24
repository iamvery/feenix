defmodule Feenix.Params do
  use Plug.Builder

  plug(:fetch_query_params)
  plug(:merge_params)

  def merge_params(conn, _opts) do
    params = Map.merge(conn.query_params, conn.path_params)
    %{conn | params: params}
  end
end
