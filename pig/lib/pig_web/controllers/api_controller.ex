defmodule PigWeb.ApiController do
  use PigWeb, :controller
  alias Pig.Crush
  alias Singyeong.{Client, Query}

  def deploys(conn, _) do
    deploys = Enum.map Crush.deployments(), &destructify/1
    json conn, deploys
  end

  def external_ports(conn, _) do
    ports =
      "agma"
      |> Query.new
      |> Client.query_metadata
      |> Enum.map(fn client ->
        client["metadata"]["deployment_ports"]
        |> Enum.map(fn {k, v} ->
          {
            k,
            Enum.map(v, fn port ->
              ip =
                case String.split(client["metadata"]["ip"], ":", parts: 2) do
                  [ip] -> ip
                  [ip, _port] -> ip
                end

              "#{ip}:#{port}"
            end)
          }
        end)
        |> Map.new
      end)
      |> Enum.reduce(%{}, fn x, acc ->
        Map.merge acc, x, fn _k, v1, v2 -> v1 ++ v2 end
      end)

    json conn, ports
  end

  defp destructify(term) when is_list(term), do: Enum.map term, &Map.from_struct/1
  defp destructify(term) when is_map(term), do: term |> Map.from_struct |> Enum.map(fn {k, v} -> {k, destructify(v)} end) |> Map.new
  defp destructify(term), do: term
end
