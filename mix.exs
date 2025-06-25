defmodule Goal.MixProject do
  use Mix.Project

  @version "1.2.2"
  @source_url "https://github.com/mtanca/goal"
  @changelog_url "https://github.com/mtanca/goal/blob/main/CHANGELOG.md"

  def project do
    [
      app: :m_goal,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A maintained fork of Goal for parameter validation based on Ecto",
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
      {:benchee, "~> 1.0", only: :dev},
      {:ecto, "~> 3.13"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:recase, "~> 0.8"}
    ]
  end

  defp package do
    [
      maintainers: ["Mark T"],
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
