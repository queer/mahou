defmodule Wand.MixProject do
  use Mix.Project

  def project do
    [
      app: :wand,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: release(),
      escript: [main_module: Wand.Application],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Wand.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.2.1"},
      {:progress_bar, "~> 2.0"},
      {:mahou, path: "../libmahou"},
    ]
  end
end
