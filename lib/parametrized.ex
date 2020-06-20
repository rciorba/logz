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

  defp make_assigns_block(values_map) do
    {values_map, _} = Code.eval_quoted(values_map)
    # IO.puts("=====")
    # IO.inspect(values_map)
    # IO.puts("=====")
    Enum.map(values_map, fn {key, val} -> quote do: unquote(var_reference(key)) = unquote(val) end)
    # |> IO.inspect
  end

  defp inject_assigns(values_map, block) do
    content = block
    |> drop_do
    |> extract_test_content
    prepend_to_content(make_assigns_block(values_map), content)
  end

  defmacro parametrized_test(name, values, block) do
    # IO.puts("--------------")
    # IO.puts(name)
    # IO.inspect(values)
    for {id, values} <- values do
      name = "#{name}[#{id}]"
      block = inject_assigns(values, block)
      ast = quote do
        test unquote(name) do
          unquote(block)
        end
      end
      # IO.inspect(ast)
      # IO.write([Macro.to_string(ast), "\n"])
      expanded = Macro.expand(ast, __ENV__)
      # IO.puts(">>>>>>>>>>>>>")
      # IO.write([Macro.to_string(expanded), '\n'])
      # IO.puts("")
      expanded
    end
  end

end
