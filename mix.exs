defmodule ExJsonSchema.Mixfile do
  use Mix.Project

  @source_url "https://github.com/jonasschmidt/ex_json_schema"
  @version "0.10.1"

  def project do
    [
      app: :ex_json_schema,
      version: @version,
      elixir: "~> 1.6",
      description: """
        A JSON Schema validator with full support for the draft 4 specification
        and zero dependencies.
      """,
      deps: deps(),
      docs: docs(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, dialyzer: :test],
      dialyzer: [
        plt_add_apps: [:ex_unit],
        plt_core_path: ".",
        plt_add_deps: :transitive
      ]
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:decimal, "~> 2.0"},
      {:dialyxir, "~> 1.2", only: [:test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:httpoison, "~> 1.8", only: :test},
      {:mix_test_watch, "~> 0.7", only: [:dev, :test]},
      {:poison, "~> 5.0", only: :test}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE),
      maintainers: ["Jonas Schmidt"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
