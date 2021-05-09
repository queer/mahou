defmodule Wand.Commands.Containers do
  alias Singyeong.{Client, Query}
  alias Wand.Cli
  require Logger

  @behaviour Wand.Command

  def run(_base_flags, argv) do
    clients =
      "agma"
      |> Query.new
      |> Client.query_metadata

    {flags, _argv} = OptionParser.parse! argv, Cli.default_parse_opts()

    if Keyword.get(flags, :all) do
      log_containers clients, "running"
      Logger.info ""
    end

    log_containers clients, "managed"
  end

  defp log_containers(clients, key) do
    containers = Enum.flat_map clients, &(&1["metadata"]["#{key}_container_ids"])
    container_names = Enum.flat_map clients, &(&1["metadata"]["#{key}_container_names"])

    Logger.info "#{key} containers: "
    if containers == [] do
      Logger.info "None"
    else
      containers
      |> Enum.zip(container_names)
      |> Enum.map(fn {id, name} -> "#{name} (#{id})" end)
      |> Enum.join("\n- ")
      |> Logger.info
    end
  end
end
