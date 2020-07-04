defmodule Para do
  require ExUnit.Case

  defp drop_do(block) do
    # IO.puts("block:")
    # IO.inspect(block)
    case block do
      [do: subblock] -> subblock
    end
  end

  defp extract_test_content(block) do
    case block do
      {:__block__, [], content} when is_list(content) -> content
      content when is_tuple(content) -> [content]
    end
  end

  defp prepend_to_content(prefix, content) do
    {:__block__, [], prefix ++ content}
  end

  defp var_reference(var) do
    {:ok, ast} = Code.string_to_quoted(to_string(var))
    ast
  end

  defp make_assigns_block(values) do
    # IO.inspect(values)
    # IO.puts("=====")
    # value = Macro.expand(values, __ENV__) |> IO.inspect
    # {values, _} = Code.eval_quoted(values)
    # IO.inspect(values)
    # IO.puts("=====")
    # IO.inspect(values)
    # IO.puts("=====")
    Enum.map(values, fn {key, val} ->
      quote do: unquote(var_reference(key)) = unquote(Macro.expand(val, __ENV__))
    end)
  end

  defp inject_assigns(values_map, block) do
    content =
      block
      |> drop_do
      |> extract_test_content

    prepend_to_content(make_assigns_block(values_map), content)
  end

  def unpack({id, values}), do: {"[#{id}]", values}

  def unpack(values) do
    id = Macro.to_string(values)
    {id, values}
  end

  defp make_name(base_name, id, index) do
    name = "#{base_name}#{id}"

    if byte_size(name) > 255 do
      "#{base_name}[#{index}]"
    else
      name
    end
  end

  defmacro parametrized_test(name, context, parameters, block) do
    # IO.inspect(name)
    # IO.puts("--------------")
    for {param, index} <- Enum.with_index(parameters) do
      {id, values} = unpack(param)
      name = make_name(name, id, index)
      block = inject_assigns(values, block)

      ast =
        quote do
          test unquote(name), unquote(context) do
            unquote(block)
          end
        end

      # IO.inspect(ast)
      # IO.write([Macro.to_string(ast), "\n"])
      # expanded = Macro.expand(ast, __ENV__)
      # IO.puts(">>>>>>>>>>>>>")
      # IO.write([Macro.to_string(expanded), '\n'])
      # # IO.puts("")
      # expanded
    end
  end

  defmacro parametrized_test(name, parameters, block) do
    quote do
      parametrized_test(unquote(name), _, unquote(parameters), unquote(block))
    end
  end

  defmacro parametrized_test(name, parameters) do
    for {param, index} <- Enum.with_index(parameters) do
      {id, values} = unpack(param)
      name = make_name(name, id, index)

      quote do
        test(unquote(name))
      end
    end
  end
end
