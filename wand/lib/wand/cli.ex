defmodule Wand.Cli do
  alias Wand.Commands
  require Logger

  @default_parse_opts [aliases: [d: :debug], switches: [debug: :boolean]]

  def default_parse_opts, do: @default_parse_opts

  def run(base_flags, argv) do
    IO.puts ""

    case argv do
      ["containers" | args] ->
        Commands.Containers.run base_flags, args

      ["create" | args] ->
        Commands.Create.run base_flags, args

      ["stop" | args] ->
        Commands.Stop.run base_flags, args

      [arg | rest] ->
        Logger.info "got arg: #{inspect arg} with data: #{inspect rest}"

      [] ->
        Logger.info "** hek u"
    end
  end
end
