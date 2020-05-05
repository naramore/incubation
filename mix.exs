defmodule Incubation.MixProject do
  use Mix.Project

  @in_production Mix.env() == :prod

  def project do
    [
      apps_path: "apps",
      version: "0.0.2",
      build_embedded: @in_production,
      start_permanent: @in_production,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        flags: [
          :underspecs,
          :error_handling,
          :unmatched_returns,
          :unknown,
          :race_conditions
        ],
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true
      ],
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
    ]
  end
end
