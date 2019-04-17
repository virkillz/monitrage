defmodule Monitrage.MixProject do
  use Mix.Project

  def project do
    [
      app: :monitrage,
      version: "0.1.0",
      elixir: "~> 1.7",
      deps: deps(),

      # Docs
      name: "Monitrage",
      source_url: "https://github.com/virkillz/monitrage",
      homepage_url: "http://virkill.com",
      docs: [
        # The main page in the docs
        main: "Monitrage",
        logo: "monitrage.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Monitrage.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.4"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
