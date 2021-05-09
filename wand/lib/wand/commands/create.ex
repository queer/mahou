defmodule Wand.Commands.Create do
  @behaviour Wand.Command

  alias Mahou.Format.App
  alias Mahou.Message
  alias Mahou.Message.CreateContainer
  alias Mahou.Parser
  alias Singyeong.{Client, Query}
  require Logger

  def run(_base_flags, argv) do
    {flags, _argv} = OptionParser.parse! argv, aliases: [f: :file], switches: [file: :string]
    if Keyword.has_key?(flags, :file) do
      case Parser.parse(Keyword.get(flags, :file)) do
        [] ->
          {:error, :no_apps}

        apps when is_list(apps) ->
          create apps
          :ok

        %App{} = app ->
          create [app]
          :ok
      end
    else
      Logger.warn "create: nothing to create S:"
      Logger.warn "create: did you remember to pass -f?"
      Logger.warn "create: (this implies eventually being able to pipe in configs via stdin)"
      {:error, :no_input}
    end
  end

  defp create(apps) do
    Logger.info "create: making #{length apps} container(s)"
    Logger.info "create: app images:\n* #{apps |> Enum.map(&("#{&1.namespace}:#{&1.name} -> #{&1.image}")) |> Enum.join("\n* ")}"

    msg =
      %CreateContainer{
        apps: apps,
      }
      |> Message.create
      |> Message.encode

    "pig"
    |> Query.new
    |> Client.send_msg(msg)

    Logger.info "create: started creation!"
  end
end
