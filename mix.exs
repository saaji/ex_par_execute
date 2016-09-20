defmodule ParExecute.Mixfile do
  use Mix.Project

  def project do
    [app: :par_execute,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :pooler, :retry],
     mod: {ParExecute, []}]
  end

  defp deps do
    [{:pooler, "~> 1.5"},
     {:retry, "~> 0.5.0"}]
  end
end
