defmodule PropBench.MixProject do
  use Mix.Project

  @in_production Mix.env() == :prod
  @version "0.0.1"

  def project do
    [
      app: :prop_bench,
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
      {:benchee, "~> 1.0"},
      {:stream_data, "~> 0.4"},
      {:propcheck, "~> 1.2"},
      {:proper, "~> 1.3"},
      {:triq, "~> 1.3"},
      {:archive, in_umbrella: true}
    ]
  end
end
