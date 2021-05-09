defmodule Wand.Commands.Stop do
  alias Mahou.Message
  alias Mahou.Message.ChangeContainerStatus
  alias Singyeong.{Client, Query}
  require Logger

  @behaviour Wand.Command

  def run(_base_args, argv) do
    {flags, argv} =
      OptionParser.parse_head! argv, aliases: [
        k: :kill,
        n: :namespace,
      ], switches: [
        kill: :boolean,
        namespace: :string,
      ]

    kill? = Keyword.get flags, :kill, false
    Logger.info "state: #{if kill?, do: "kill", else: "stop"}: containers:\n* #{Enum.join argv, "\n* "}"
    for app_name <- argv do
      msg = %ChangeContainerStatus{
          name: app_name,
          namespace: Keyword.get(flags, :namespace, nil),
          command: if(kill?, do: :kill, else: :stop),
        }
        |> Message.create
        |> Message.encode

      "pig"
      |> Query.new
      |> Client.send_msg(msg)
    end
  end
end
