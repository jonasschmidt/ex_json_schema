defmodule ExJsonSchema.Mixfile do
  use Mix.Project

  @source_url "https://github.com/jonasschmidt/ex_json_schema"
  @version "0.7.4"

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
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:httpoison, "~> 0.8", only: :test},
      {:mix_test_watch, "~> 0.2.6", only: [:dev, :test]},
      {:poison, "~> 1.5", only: :test}
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
end
