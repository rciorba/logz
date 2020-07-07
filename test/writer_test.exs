defmodule WriterTest do
  use ExUnit.Case
  import Parameterize
  alias Logz.Writer
  doctest Writer

  parameterized_test(
    "doc_id",
    [
      [doc: %{a: 1, b: 2}, id: "9C3B6457"],
      [doc: %{a: 2, b: 1}, id: "D54D5BC3"]
    ]
  ) do
    assert Writer.doc_id(doc) == id
  end

  parameterized_test(
    "values_to_string",
    [
      [doc: %{a: 1, b: 2}, expected: "12"],
      [doc: %{a: 2, b: 1}, expected: "21"]
    ]
  ) do
    assert Writer.values_to_string(doc) == expected
  end
end
