defmodule Shoujo.MixProject do
  use Mix.Project

  def project do
    [
      app: :shoujo,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Shoujo.Application, []}
    ]
  end

  defp deps do
    [
      {:mahou, path: "../libmahou"},
      {:ranch, "~> 2.0"},
    ]
  end
end
