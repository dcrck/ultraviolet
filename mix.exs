defmodule Ultraviolet.MixProject do
  use Mix.Project

  @repo_url "https://github.com/dcrck/ultraviolet"
  @version "0.1.0"

  def project do
    [
      app: :ultraviolet,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # tests
      test_coverage: [tool: ExCoveralls],
      # Hex
      package: package(),
      description: "A color manipulation library designed to work like chroma-js",
      # Docs
      name: "Ultraviolet",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # required for floating point math in LAB / LCH space
      {:decimal, "~> 2.0"},
      # only required to parse colorbrewer.json file
      {:jason, "~> 1.4", optional: true, runtime: false},
      # test coverage
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp package do
    [
      maintainers: "Derek Meer",
      licenses: ["MIT"],
      links: %{
        "Codeberg" => "https://codeberg.org/meerific/uv",
        "GitHub" => @repo_url
      }
    ]
  end

  defp docs do
    [
      main: "Ultraviolet",
      source_ref: "v#{@version}",
      source_url: @repo_url,
      homepage_url: "https://codeberg.org/meerific/uv",
      extras: [
        "README.md": [title: "README"],
        "LICENSE.md": [title: "License"]
      ]
    ]
  end
end
