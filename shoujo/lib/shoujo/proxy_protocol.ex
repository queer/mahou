defmodule Shoujo.ProxyProtocol do
  use GenServer
  require Logger

  @behaviour :ranch_protocol

  def start_link(ref, transport, opts) do
    GenServer.start_link __MODULE__, [ref, transport, opts]
  end

  def init([ref, transport, [port: port]]) do
    :ok = :proc_lib.init_ack {:ok, self()}
    {:ok, socket} = :ranch.handshake ref
    :ok = transport.setopts socket, [active: true]
    target =
      :ports
      |> :ets.lookup(port)
      |> hd
      |> elem(1)
      |> Enum.random

    [target_ip, target_port] =
      case String.split(target, ":", parts: 2) do
        [target_ip] -> [target_ip, "80"]
        [target_ip, target_port] -> [target_ip, target_port]
      end

    target_port = String.to_integer target_port
    {:ok, proxy_socket} = :gen_tcp.connect to_charlist(target_ip), target_port, [:binary, {:active, true}]

    state =
      %{
        port: port,
        target: target,
        socket: socket,
        transport: transport,
        proxy_socket: proxy_socket,
        first_message: false,
      }

    :gen_server.enter_loop __MODULE__, [], state
  end

  def handle_info({:tcp, socket, data}, state) do
    cond do
      socket == state.socket ->
        # state =
        #   if not state.first_message do
        #     case data do
        #       "GET /" <> _rest -> Logger.info "GET REQUEST!!!"
        #       _ -> nil
        #     end
        #     %{state | first_message: true}
        #   else
        #     state
        #   end

        :gen_tcp.send state.proxy_socket, data
        {:noreply, state}

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
end
