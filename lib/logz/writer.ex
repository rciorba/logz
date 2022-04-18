defmodule Logz.Writer do
  defp mapping(es_type, options \\ []) do
    schema = %{
      "type" => es_type
    }

    # {analyzed, options} = Keyword.pop_first(options, :analyzed, true)

    # schema =
    #   case analyzed do
    #     true ->
    #       schema

    #     false ->
    #       Map.put(schema, "index", "false")
    #   end

    Enum.into(options, schema)
  end

  def create_template(es_url) do
    template = %{
      "index_patterns" => ["logz-*"],
      "settings" => %{
        "number_of_shards" => 1,
        "number_of_replicas" => 0,
        "index.codec" => "best_compression",
        "refresh_interval" => "10s",
        "analysis" => %{
          "tokenizer" => %{
            "url_tokenizer" => %{
              "type" => "pattern",
              "pattern" => "[/?=;&]"
            }
          },
          "analyzer" => %{
            "custom_url" => %{
              "type" => "custom",
              "tokenizer" => "url_tokenizer"
            }
          }
        }
      },
      "mappings" => %{
        "_meta" => %{
          "schema_version" => "2020-06-07-0"
        },
        # ignore fields if not in mapping
        "dynamic" => "false",
        "properties" => %{
          "size" => mapping("integer"),
          "host" => mapping("keyword"),
          "uri" =>
            mapping(
              "text",
              analyzer: "custom_url"
            ),
          "status" => mapping("integer"),
          "request_method" => mapping("keyword"),
          "request" => mapping("text", index: false),
          "user_agent" => mapping("text"),
          "tstamp" => mapping("date", format: "strict_date_optional_time"),
          "addr" => mapping("ip")
        }
      }
    }

    IO.inspect("url: #{es_url}/_template/logz")
    template = :jiffy.encode(template, [:use_nil, :pretty])
    IO.puts(template)

    resp =
      HTTPoison.put!(
        "#{es_url}/_template/logz",
        template,
        [{"Content-Type", "application/json"}]
      )

    IO.inspect(resp)

    case resp do
      %{status_code: 200} ->
        :ok

      _ ->
        {:error, %{status: resp.status_code, body: resp.body}}
    end
  end

  defp index_name(doc) do
    name =
      doc.tstamp
      |> DateTime.from_unix!()
      |> DateTime.to_date()
      |> Date.to_string()

    "logz-#{name}"
  end

  def flush([], _) do
  end

  def flush(batch, index_name) do
    IO.inspect(index_name)
    # IO.inspect(batch)
    Elastix.Bulk.post("http://localhost:9220/", batch,
      index: index_name,
      httpoison_options: [timeout: 180_000]
    )
  end

  def add_to_batch(id, doc, {batch, batch_size, current_index_name, index})
      when batch_size >= 200 do
    flush(batch, current_index_name)
    add_to_batch(id, doc, {[], 0, current_index_name, index})
  end

  def add_to_batch(id, doc, {batch, batch_size, current_index_name, index}) do
    {
      [
        %{index: %{_id: id}},
        doc | batch
      ],
      batch_size + 1,
      current_index_name,
      index
    }
  end

  def values_to_string(doc) do
    doc
    |> Map.to_list()
    |> Enum.sort()
    |> Enum.map(fn {_, val} -> to_string(val) end)
    |> Enum.join()
  end

  def doc_id(doc) do
    <<q1::size(32), q2::size(32), q3::size(32), q4::size(32)>> =
      :crypto.hash(:md5, values_to_string(doc))

    <<:erlang.bxor(
        :erlang.bxor(q1, q2),
        :erlang.bxor(q3, q4)
      )::size(32)>>
    |> Base.encode16()
  end

  defp strformat(tstamp) do
    dt = DateTime.from_unix!(tstamp)

    :io_lib.format(
      "~4..0B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0B",
      [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
    )
    |> to_string
  end

  def reduce(doc, {batch, batch_size, current_index_name, index}) do
    doc_index_name = index_name(doc)
    id = doc_id(doc)
    tstamp = doc[:tstamp] |> strformat()
    doc = Map.put(doc, :tstamp, tstamp)
    # IO.puts(:jiffy.encode(doc, [:use_nil, :pretty]))

    case doc_index_name do
      ^current_index_name ->
        # IO.inspect({1, current_index_name})
        add_to_batch(id, doc, {batch, batch_size, current_index_name, index})

      new_index_name ->
        # IO.inspect({2, new_index_name})
        flush(batch, current_index_name)
        add_to_batch(id, doc, {[], 0, new_index_name, index})
    end
  end
end

defmodule Logz.Writer.Collectible do
  defstruct [:batch_size, :batch, :current_index_name]
end

# defimpl Collectible, for: Logz.Writer.Collectible do

# end
