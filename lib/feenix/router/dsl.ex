defmodule Feenix.Router.DSL do
  for method <- [:get, :post, :put, :patch, :delete] do
    defmacro unquote(method)(path, module, action) do
      method = Plug.Router.Utils.normalize_method(unquote(method))
      build(method, path, module, action)
    end
  end

  defp build(method, path, module, action) do
    {_vars, path_info} = Plug.Router.Utils.build_path_match(path)

    quote do
      def do_match(conn, unquote(method), unquote(path_info)) do
        unquote(module).call(conn, unquote(action))
      end
    end
  end
end
