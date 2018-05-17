defmodule Feenix.Controller do
  defmacro __using__(_opts) do
    quote do
      use Plug.Builder
      plug(:apply_action)

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
end
