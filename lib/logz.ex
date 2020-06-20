defmodule Logz do
  @moduledoc """
  Documentation for `Logz`.
  """

  require Logger

  defp parse(doc) do
    case Logz.Nginx.parse(doc) do
      {:ok, data} -> data
      {:error, reason} ->
        Logger.error("Malformed line: #{inspect(reason)}")
        nil
    end
  end

  def import() do
    {batch, _batch_size, index_name, _} = IO.stream(:stdio, :line)
    |> Stream.map(&parse/1)
    |> Stream.filter(&(not is_nil(&1)))
    # |> Stream.map(&IO.inspect/1)
    |> Enum.reduce({[], 0, nil, 1}, &Logz.Writer.reduce/2)

    Logz.Writer.flush(batch, index_name)
  end

  def create_template(_) do
    IO.puts("creating template")

    Logz.Writer.create_template("http://localhost:9200")
    |> IO.inspect()
  end
end
