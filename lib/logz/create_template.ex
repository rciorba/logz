defmodule Mix.Tasks.CreateTemplate do
  @shortdoc "create template"
  @moduledoc "create template"

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    IO.inspect(argv)
    Application.ensure_all_started(:hackney)
    Logz.create_template(argv)
  end
end
