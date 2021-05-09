defmodule Mahou.MixProject do
  use Mix.Project

  def project do
    [
      app: :mahou,
      version: "0.1.0",
      elixir: "~> 1.11",
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
      {:typed_struct, "~> 0.2.1"},
      {:gen_json_schema, "~> 0.1.0"},
      {:annotatable, "~> 0.1.2"},
      {:ex_json_schema, "~> 0.7.4"},
      {:singyeong, "~> 0.4.0"},
      {:peek, "~> 0.2.0"},
    ]
  end
end
