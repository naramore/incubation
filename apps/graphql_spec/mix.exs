defmodule GraphqlSpec.MixProject do
  use Mix.Project

  @in_production Mix.env() == :prod
  @version "0.0.1"

  def project do
    [
      app: :graphql_spec,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: @in_production,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},
      {:stream_data, "~> 0.4"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
