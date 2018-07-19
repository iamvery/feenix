defmodule Feenix.Router do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__).DSL

      use Plug.Builder

      def match(conn, _opts) do
        do_match(conn, conn.method, conn.path_info)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      plug(:match)

      def do_match(conn, _method, _path_info) do
        send_resp(conn, 404, "not found")
      end
    end
  end
end
