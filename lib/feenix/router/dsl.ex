defmodule Feenix.Router.DSL do
  defmacro get(path, module, action) do
    {_vars, path_info} = Plug.Router.Utils.build_path_match(path)

    quote do
      def do_match(conn, "GET", unquote(path_info)) do
        unquote(module).call(conn, unquote(action))
      end
    end
  end

  defmacro post(path, module, action) do
    {_vars, path_info} = Plug.Router.Utils.build_path_match(path)

    quote do
      def do_match(conn, "POST", unquote(path_info)) do
        unquote(module).call(conn, unquote(action))
      end
    end
  end
end
