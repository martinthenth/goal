defmodule Goal.MixProject do
  use Mix.Project

  @version "0.2.4"
  @source_url "https://github.com/martinthenth/goal"
  @changelog_url "https://github.com/martinthenth/goal/blob/main/CHANGELOG.md"

  def project do
    [
      app: :goal,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A parameter validation library based on Ecto",
      source_ref: @version,
      source_url: @source_url,
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.9"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:recase, "~> 0.5"}
    ]
  end

  defp package do
    [
      maintainers: ["Martin Nijboer"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url, "Changelog" => @changelog_url}
    ]
  end

  defp docs do
    [
      main: "Goal",
      extras: ["README.md"]
    ]
  end
end
