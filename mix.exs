defmodule Magic.MixProject do
  use Mix.Project

  def project do
    [
      app: :magic,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:tesla, "~> 1.4"},

      # optional, but recommended adapter
      {:hackney, "~> 1.17"},

      # optional, required by JSON middleware
      {:jason, ">= 1.0.0"},
      {:nimble_csv, "~> 1.1"},
      {:map_diff, "~> 1.3"},
      {:decimal, "~> 2.1"},
      {:floki, "~> 0.36.0"}
    ]
  end
end
