defmodule Feenix.Controller do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      use Plug.Builder

      def call(conn, action) do
        conn
        |> put_private(:action, action)
        |> super(nil)
      end

      def apply_action(conn, _opts) do
        apply(__MODULE__, conn.private.action, [conn])
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      plug(:apply_action)
    end
  end
end
