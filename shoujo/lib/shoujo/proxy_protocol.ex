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
        request_id: nil,
      }

    :gen_server.enter_loop __MODULE__, [], state
  end

  def handle_info({:tcp, socket, data}, state) do
    cond do
      socket == state.socket ->
        if is_http_request?(data) do
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

          request_id = Ksuid.generate()

          output_data =
            lines
            |> Enum.concat(["x-mahou-shoujo-request-id: #{request_id}"])
            |> Enum.join("\r\n")
            |> Kernel.<>("\r\n\r\n")

          :gen_tcp.send state.proxy_socket, output_data

          {:noreply, %{state | request_id: request_id}}
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
        if is_http_response?(data) do
          [headers | [rest | _]] =
            data
            |> String.trim
            |> String.split("\r\n\r\n", parts: 2)

          output_data = headers <> "\r\nx-mahou-shoujo-request-id: #{state.request_id}\r\n\r\n" <> rest
          state.transport.send state.socket, output_data

          {:noreply, state}
        else
          state.transport.send state.socket, data
          {:noreply, state}
        end
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

  defp is_http_request?(data) do
    method? =
      case data do
        "GET"     <> _rest -> true
        "POST"    <> _rest -> true
        "PUT"     <> _rest -> true
        "DELETE"  <> _rest -> true
        "HEAD"    <> _rest -> true
        "OPTIONS" <> _rest -> true
        _                  -> false
      end

    method? and byte_size(data) > 4 and binary_part(data, byte_size(data), -4) == "\r\n\r\n"
  end

  defp is_http_response?("HTTP/1.1" <> _), do: true
  defp is_http_response?(_), do: false
end
