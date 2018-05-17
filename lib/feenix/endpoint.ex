defmodule Feenix.Endpoint do
  defmacro __using__(_opts) do
    quote do
      def start_link do
        options = []
        Plug.Adapters.Cowboy.http(__MODULE__, options)
      end

      use Plug.Builder
    end
  end
end
