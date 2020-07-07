defmodule NginxTest do
  use ExUnit.Case
  import Parameterize
  alias Logz.Nginx
  doctest Nginx

  defp naive_to_unix(ndt) do
    NaiveDateTime.diff(ndt, ~N[1970-01-01 00:00:00], :second)
  end

  parameterized_test(
    "parse",
    [
      [
        line:
          "1.2.3.4 - - [07/Jun/2020:06:40:03 +0000] \"GET /blog HTTP/1.1\" 301 185 \"-\" \"Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5\"\n",
        expected: %{
          addr: "1.2.3.4",
          tstamp: naive_to_unix(~N[2020-06-07 06:40:03]),
          request_method: "GET",
          uri: "/blog",
          request: "GET /blog HTTP/1.1",
          status: "301",
          size: "185",
          user_agent: "Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5"
        }
      ],
      [
        line:
          "1.2.3.4 - - [07/Jun/2020:06:40:03 +0000] \"\" 301 185 \"-\" \"Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5\"\n",
        expected: %{
          addr: "1.2.3.4",
          request: "",
          request_method: nil,
          size: "185",
          status: "301",
          tstamp: 1_591_512_003,
          uri: nil,
          user_agent: "Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5"
        }
      ],
      [
        line:
          "1.2.3.4 - - [25/May/2020:02:06:51 +0000] \"POST /%75%73%65%72%2e%70%68%70 HTTP/1.1\" 404 571 \"554fcae493e564ee0dc75bdf2ebf94caads|a:3:{s:2:\\x22id\\x22;s:3:\\x22'/*\\x22;s:3:\\x22num\\x22;s:141:\\x22*/ union select 1,0x272F2A,3,4,5,6,7,8,0x7b247b24524345275d3b6469652f2a2a2f286d6435284449524543544f52595f534550415241544f5229293b2f2f7d7d,0--\\x22;s:4:\\x22name\\x22;s:3:\\x22ads\\x22;}554fcae493e564ee0dc75bdf2ebf94ca\" \"Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)\"\n",
        expected: %{
          addr: "1.2.3.4",
          tstamp: naive_to_unix(~N[2020-05-25 02:06:51]),
          request_method: "POST",
          uri: "/%75%73%65%72%2e%70%68%70",
          request: "POST /%75%73%65%72%2e%70%68%70 HTTP/1.1",
          status: "404",
          size: "571",
          user_agent: "Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
        }
      ]
    ]
  ) do
    assert Nginx.parse!(line) == expected
  end

  parameterized_test(
    "parse date",
    [
      [str: "07/Jun/2020:06:40:03 +0000", exp: ~N[2020-06-07 06:40:03]],
      [str: "07/Jun/2020:06:40:03 +0200", exp: ~N[2020-06-07 08:40:03]]
    ]
  ) do
    assert Nginx.parse_date!(str) == naive_to_unix(exp)
  end

  parameterized_test(
    "parse request",
    [
      [req: "GET /foo?bar=1&baz=2 HTTP/1.1", expected: {"GET", "/foo?bar=1&baz=2"}],
      [
        req: "POST /%75%73%65%72%2e%70%68%70 HTTP/1.1",
        expected: {"POST", "/%75%73%65%72%2e%70%68%70"}
      ],
      [
        req: "\x03\x00\x00/*\xE0\x00\x00\x00\x00\x00Cookie: mstshash=Administr",
        expected: {nil, nil}
      ]
    ]
  ) do
    assert Nginx.parse_request(req) == expected
  end
end
