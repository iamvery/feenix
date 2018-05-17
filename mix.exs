defmodule BuildFeenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :build_feenix,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {YourApp, []},
      applications: [:logger, :plug, :cowboy],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:plug, "~>1.0"}, {:cowboy, "~>1.0"}]
  end
end
