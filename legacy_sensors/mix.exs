defmodule Main.MixProject do
  use Mix.Project

  def project do
    [
      app: :legacy_sensors,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:elixir_xml_to_map],
      extra_applications: [:logger],
      mod: {Main, [0, 0]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventsource_ex, "~> 0.0.2"},
      {:poison, "~> 3.1"},
      {:elixir_xml_to_map, "~> 1.0"}
    ]
  end
end
