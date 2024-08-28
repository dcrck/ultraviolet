defmodule Ultraviolet.MixProject do
  use Mix.Project

  def project do
    [
      app: :ultraviolet,
      version: "0.0.1",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # required for floating point math in LAB / LCH space
      {:decimal, "~> 2.0"},
      # only required to parse colorbrewer.json file
      {:jason, "~> 1.4", optional: true, runtime: false},
    ]
  end
end
