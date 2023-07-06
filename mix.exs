defmodule LiveViewGrid.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_view_grid,
      version: "0.0.1-alpha",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "LiveViewGrid",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: [
        main: "LiveViewGrid", # The main page in the docs
        extras: ["README.md"]
      ]
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
      {:ord_map, "~> 0.1"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.19.3"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
    ]
  end

  defp aliases() do[
    build_assets: ["tailwind default --minify", "esbuild default --minify"],
    build: ["build_assets", "compile"]
  ]

  end
end
