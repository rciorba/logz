defmodule Logz.Nginx do
  @moduledoc """
  Implements a Stream that reads from files and emits maps.
  """

  require Logger

  defp parse_month(str) do
    case str do
      "Jan" -> 1
      "Feb" -> 2
      "Mar" -> 3
      "Apr" -> 4
      "May" -> 5
      "Jun" -> 6
      "Jul" -> 7
      "Aug" -> 8
      "Sep" -> 9
      "Oct" -> 10
      "Nov" -> 11
      "Dec" -> 12
    end
  end

  defp offset(sign, hours, minutes) do
    off = String.to_integer(hours) * 3600 + String.to_integer(minutes) * 60

    case sign do
      "+" -> off
      "-" -> -off
    end
  end

  def parse_date!(str) do
    case Regex.scan(~r{(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+) (\+|-)(\d\d)(\d\d)}, str) do
      [[_, day, month, year, hour, minute, second, off_sign, off_hour, off_min]] ->
        {:ok, date} =
          NaiveDateTime.new(
            String.to_integer(year),
            parse_month(month),
            String.to_integer(day),
            String.to_integer(hour),
            String.to_integer(minute),
            String.to_integer(second)
          )

        tstamp =
          NaiveDateTime.add(date, offset(off_sign, off_hour, off_min), :second)
          |> NaiveDateTime.diff(~N[1970-01-01 00:00:00], :second)

        tstamp

      matched ->
        throw({:error, matched})
    end
  end

  def parse_request(request) do
    case Regex.scan(~r{([a-zA-Z]+) ([^\s]+) [^\"]+}, request) do
      [[_, method, uri]] ->
        {method, uri}

      _ ->
        {nil, nil}
    end
  end

  def parse(line) do
    # 162.243.6.123 - - [07/Jun/2020:06:40:03 +0000] "GET /blog HTTP/1.1" 301 185 "-" "UA"
    addr = ~S{([^\s]*)}
    tstamp = ~S{\[(.*)\]}
    request = ~S{"(.*)"}
    status = ~S{([\d]+)}
    size = ~S{([\d]+)}
    user_agent = ~s{"(.*)"}

    case Regex.scan(
           ~r/#{addr} - - #{tstamp} #{request} #{status} #{size} ".*" #{user_agent}/,
           line
         ) do
      [[_, addr, tstamp, request, status, size, user_agent]] ->
        {method, uri} = parse_request(request)

        {:ok,
         %{
           addr: addr,
           tstamp: parse_date!(tstamp),
           request_method: method,
           uri: uri,
           request: request,
           status: status,
           size: size,
           user_agent: user_agent
         }}

      matched ->
        # IO.inspect(line)
        {:error, {line, matched}}
    end
  end

  def parse!(line) do
    {:ok, data} = parse(line)
    data
  end
end
