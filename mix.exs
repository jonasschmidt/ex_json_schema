defmodule ExJsonSchema.Mixfile do
  use Mix.Project

  @source_url "https://github.com/jonasschmidt/ex_json_schema"
  @version "1.0.0"

  def project do
    [
      app: :ex_json_schema,
      version: @version,
      elixir: "~> 1.15",
      description: """
        A JSON Schema compiler and validator for drafts 4, 6, 7, and 2020-12
      """,
      deps: deps(),
      docs: docs(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:ex_unit]
      ]
    ]
  end

  def application do
    [extra_applications: []]
  end

  def cli do
    [preferred_envs: [coveralls: :test, dialyzer: :test]]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:httpoison, "~> 1.8", only: :test},
      {:mix_test_watch, "~> 1.3.0", only: [:dev, :test]},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.5", only: :test},
      {:phoenix, "~> 1.6", only: :test}
    ]
  end

  defp docs do
    [
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/migration-to-1.0.md",
        "guides/format-support.md",
        "guides/security.md",
        "guides/conformance.md"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      files: ~w(lib guides mix.exs README.md CHANGELOG.md LICENSE),
      maintainers: ["Jonas Schmidt"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
