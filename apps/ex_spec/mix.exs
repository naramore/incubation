defmodule ExSpec.MixProject do
  use Mix.Project

  @in_production Mix.env() == :prod
  @version "0.0.1"
  @source_url "https://github.com/mnaramore/ex_spec"

  def project do
    [
      app: :ex_spec,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: @in_production,
      start_permanent: @in_production,
      package: package(),
      source_url: @source_url,
      docs: [
        source_ref: "v#{@version}",
        formatters: ["html", "epub"],
      ],
      deps: deps()
    ]
  end

  defp package do
    [
      description: "clojure.spec for Elixir",
      files: ~w(lib mix.exs README.md CHANGELOG.md .formatter.exs),
      maintainers: ["Michael Naramore"],
      licenses: ["MIT"],
      links: %{
        Changelog: "#{@source_url}/blob/master/CHANGELOG.md",
        GitHub: @source_url
      }
    ]
  end

  defp elixirc_paths(env) when env in [:test, :dev],
    do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :stream_data]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 0.4", optional: true, only: [:dev, :test]},
      {:ex_doc, "~> 0.21", only: [:dev, :test]}
    ]
  end
end
