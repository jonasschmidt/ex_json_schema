defmodule NExJsonSchema.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nex_json_schema,
      version: "0.6.0",
      elixir: "~> 1.0",
      description: "A JSON Schema validator with full support for the draft 4 specification and zero dependencies.",
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: []]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.11", only: :test},
      {:poison, "~> 3.1", only: :test},
      {:excoveralls, "~> 0.6", only: :test},
      {:mix_test_watch, "~> 0.3.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE),
      maintainers: ["Jonas Schmidt", "Nebo #15"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nebo15/nex_json_schema"}
    ]
  end
end
