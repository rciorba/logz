defmodule Logz.JiffyCodec do
  @behaviour Elastix.JSON.Codec

  def encode!(data) do
    try do
      :jiffy.encode(data)
    catch
      err, value ->
        IO.inspect({err, value})
        IO.inspect(data)
        throw({err, value})
    end
  end

  def decode(json, opts \\ []), do: {:ok, :jiffy.decode(json, opts)}
end
