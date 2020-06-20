defmodule NginxTest do
  use ExUnit.Case
  import Para
  alias Logz.Nginx
  doctest Nginx

  defp naive_to_unix(ndt) do
    NaiveDateTime.diff(ndt, ~N[1970-01-01 00:00:00], :second)
  end

  test "parse" do
    line =
      "1.2.3.4 - - [07/Jun/2020:06:40:03 +0000] \"GET /blog HTTP/1.1\" 301 185 \"-\" \"Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5\"\n"

    assert Nginx.parse!(line) == %{
             addr: "1.2.3.4",
             tstamp: naive_to_unix(~N[2020-06-07 06:40:03]),
             request_method: "GET",
             uri: "/blog",
             request: "GET /blog HTTP/1.1",
             status: "301",
             size: "185",
             user_agent: "Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5"
           }
  end

  test "parse empty request" do
    line =
      "1.2.3.4 - - [07/Jun/2020:06:40:03 +0000] \"\" 301 185 \"-\" \"Mozilla/5.0 (X11; U; Linux i686; it; rv:1.8) Gecko/20060113 Firefox/1.5\"\n"

    assert {:ok, _} = Nginx.parse(line)
  end

  test "parse 2" do
    line  = "1.2.3.4 - - [25/May/2020:02:06:51 +0000] \"POST /%75%73%65%72%2e%70%68%70 HTTP/1.1\" 404 571 \"554fcae493e564ee0dc75bdf2ebf94caads|a:3:{s:2:\\x22id\\x22;s:3:\\x22'/*\\x22;s:3:\\x22num\\x22;s:141:\\x22*/ union select 1,0x272F2A,3,4,5,6,7,8,0x7b247b24524345275d3b6469652f2a2a2f286d6435284449524543544f52595f534550415241544f5229293b2f2f7d7d,0--\\x22;s:4:\\x22name\\x22;s:3:\\x22ads\\x22;}554fcae493e564ee0dc75bdf2ebf94ca\" \"Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)\"\n"
    assert Nginx.parse!(line) == %{
      addr: "1.2.3.4",
      tstamp: naive_to_unix(~N[2020-05-25 02:06:51]),
      request_method: "POST",
      uri: "/%75%73%65%72%2e%70%68%70",
      request: "POST /%75%73%65%72%2e%70%68%70 HTTP/1.1",
      status: "404",
      size: "571",
      user_agent: "Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
    }
  end

  parametrized_test("parse date",
    no_offset:   [str: "07/Jun/2020:06:40:03 +0000", exp: ~N[2020-06-07 06:40:03]],
    with_offset: [str: "07/Jun/2020:06:40:03 +0200", exp: ~N[2020-06-07 08:40:03]]
  ) do
    assert Nginx.parse_date!(str) == naive_to_unix(exp)
  end

  test "parse request" do
    assert Nginx.parse_request("GET /foo?bar=1&baz=2 HTTP/1.1") == {"GET", "/foo?bar=1&baz=2"}
    assert Nginx.parse_request("POST /%75%73%65%72%2e%70%68%70 HTTP/1.1") == {"POST", "/%75%73%65%72%2e%70%68%70"}
    assert Nginx.parse_request("\x03\x00\x00/*\xE0\x00\x00\x00\x00\x00Cookie: mstshash=Administr") == {nil, nil}
  end

  parametrized_test "PARA 1", [ok: %{}] do
    assert 1 == 1
  end

  parametrized_test "PARA 2", [ok: %{}], do: assert 1 == 1


  parametrized_test("parse_date_para",
    ok: [val: 1, exp: 1],
    bad: [val: 1, exp: 2],
  ) do
    assert val == exp
  end

  # parametrized_test "parse_date_para", [ok: 1, bad: 2] do
  # end

end
