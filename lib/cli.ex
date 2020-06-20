defmodule Mix.Tasks.Import do
  @shortdoc "import logs"
  @moduledoc "import logs"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Application.ensure_all_started(:hackney)
    Logz.import()
  end
end
