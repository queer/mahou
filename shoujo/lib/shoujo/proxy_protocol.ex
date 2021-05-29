defmodule Shoujo.ProxyProtocol do
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, transport, opts) do
    # GenServer.start_link __MODULE__, [ref, transport, opts]
    :proc_lib.start_link __MODULE__, :init, [[ref, transport, opts]]
  end

  def init([ref, transport, [port: port]]) do
    :ok = :proc_lib.init_ack {:ok, self()}
    {:ok, socket} = :ranch.handshake ref
    :ok = transport.setopts socket, [active: true]

    state =
      %{
        port: port,
        socket: socket,
        transport: transport,
        proxy_socket: nil,
        first_message: false,
      }

    :gen_server.enter_loop __MODULE__, [], state
  end

  def handle_info({:tcp, socket, data}, state) do
    cond do
      socket == state.socket ->
        is_probably_http =
          case data do
            "GET"     <> _rest -> true
            "POST"    <> _rest -> true
            "PUT"     <> _rest -> true
            "DELETE"  <> _rest -> true
            "HEAD"    <> _rest -> true
            "OPTIONS" <> _rest -> true
            _                 -> false
          end

        if is_probably_http && byte_size(data) > 4 and binary_part(data, byte_size(data), -4) == "\r\n\r\n" do
          lines =
            data
            |> String.trim
            |> String.split("\r\n")

          [_verb, path, _http_version] =
            lines
            |> hd
            |> String.split(" ")

          host =
            lines
            |> Enum.map(&String.downcase/1)
            |> Enum.filter(&String.starts_with?(&1, "host: "))
            |> case do
              [] -> nil
              [host | _] ->
                host
                |> String.replace(~r/^host:/, "")
                |> String.trim
            end

          target =
            :ports
            |> :ets.lookup(state.port)
            |> hd
            |> elem(1)
            |> case do
              elems when not is_nil(host) or not is_nil(path) ->
                Enum.filter elems, fn {_targets, inner_host, inner_path} ->
                  (host == nil or inner_host == nil or host == inner_host) and (path == nil or inner_path == nil or path == inner_path)
                end

              elems -> elems
            end
            |> Enum.flat_map(fn {targets, _, _} -> targets end)
            |> Enum.random

          state =
            if state.proxy_socket == nil do
              %{state | proxy_socket: open_socket(target)}
            else
              state
            end

          output_data =
            lines
            |> Enum.concat(["x-mahou-shoujo-request-id: #{Ksuid.generate()}"])
            |> Enum.join("\r\n")
            |> Kernel.<>("\r\n\r\n")

          :gen_tcp.send state.proxy_socket, output_data

          {:noreply, state}
        else
          target =
            :ports
            |> :ets.lookup(state.port)
            |> hd
            |> elem(1)
            |> Enum.flat_map(fn {targets, _, _} -> targets end)
            |> Enum.random

          state =
            if state.proxy_socket == nil do
              %{state | proxy_socket: open_socket(target)}
            else
              state
            end

          :gen_tcp.send state.proxy_socket, data
          {:noreply, state}
        end

      socket == state.proxy_socket ->
        state.transport.send state.socket, data
        {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, _socket}, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp open_socket(target) do
    [target_ip, target_port] =
      case String.split(target, ":", parts: 2) do
        [target_ip] -> [target_ip, "80"]
        [target_ip, target_port] -> [to_charlist(target_ip), target_port]
      end

    target_port = String.to_integer target_port
    {:ok, proxy_socket} = :gen_tcp.connect target_ip, target_port, [:binary, {:active, true}]
    proxy_socket
  end
end
