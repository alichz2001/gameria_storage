defmodule GameriaStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :gameria_storage,
      version: "0.1.0",
      build_path: "./_build",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.9.4"}
    ]
  end
end
