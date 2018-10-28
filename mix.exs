defmodule ShuntingYard.MixProject do
  use Mix.Project

  def project do
    [
      app: :shunting_yard,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.10", only: [:test]},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
    ]
  end
end
