defmodule Mahou.Singyeong do
  @metadata_version "v1"

  def supervisor(dsn, consumer) when is_binary(dsn) and is_atom(consumer) do
    [
      {__MODULE__.Supervisor, {dsn, consumer}}
    ]
  end

  def child_specs(dsn, consumer) do
    [
      {Singyeong.Client, {guess_internal_ip(), Singyeong.parse_dsn(dsn)}},
      Singyeong.Producer,
      consumer,
    ]
  end

  def metadata_version, do: @metadata_version

  defp guess_internal_ip do
    super_secret_docker_bypass? = System.get_env("__DO_NOT_RUN_THIS_IN_DOCKER_OR_YOU_WILL_BE_FIRED_INTO_THE_SUN") != nil

    # TODO: THIS DOES NOT SUPPORT IPv6
    :inet.getifaddrs()
    |> elem(1)
    |> Enum.reject(fn
      # Reject obvious loopbacks
      {'lo', _} -> true
      {_, [{:flags, flags} | _]} -> :loopback in flags
      {_ifname, opts} ->
        # If it doesn't have an addr, that means it's probably not used, even
        # tho it might be up
        missing_addr? = not Keyword.has_key? opts, :addr

        # If the if has a 169.254.x.x address, DHCP is kabork and you
        # probably shouldn't trust it
        no_dhcp_addr? =
          if Keyword.has_key?(opts, :addr) do
            {one, two, _, _} = Keyword.get opts, :addr
            one == 169 and two == 254
          else
            false
          end

        # Docker traditionally (seems to?) use the 172.16.0.0 - 172.31.255.255
        # range for containers/ its own ifs, so we try to avoid that.
        docker_addr? =
          if Keyword.has_key?(opts, :addr) and not super_secret_docker_bypass? do
            {one, two, _, _} = Keyword.get opts, :addr
            one == 172 and (two >= 16 and two <= 31)
          else
            false
          end

        is_not_internal? =
          case Keyword.get(opts, :addr, nil) do
            {192, 168, _, _} -> false
            {10, _, _, _} -> false
            {172, x, _, _} when x >= 16 and x <= 31 and super_secret_docker_bypass? -> false
            _ -> true
          end

        Enum.any? [missing_addr?, no_dhcp_addr?, docker_addr?, is_not_internal?]
    end)
    |> hd
    |> elem(1)
    |> Keyword.get(:addr)
    |> tuple_to_ip
    |> Kernel.<>(":")
    |> Kernel.<>(guess_port())
  end

  defp tuple_to_ip({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end

  defp guess_port do
    :code.all_loaded
    |> Enum.map(fn {m, _} -> m end)
    |> Enum.filter(fn m ->
      m
      |> Atom.to_string
      |> String.match?(~r/^Elixir\..*Web.Endpoint$/)
    end)
    |> case do
      [] ->
        guess_port_from_env()

      [endpoint | _] when is_atom(endpoint) ->
        opts = endpoint.config :http

        if Keyword.has_key?(opts, :port) do
          opts |> Keyword.get(:port) |> Integer.to_string
        else
          opts = endpoint.config :https

          if Keyword.has_key?(opts, :port) do
            opts |> Keyword.get(:port) |> Integer.to_string
          else
            guess_port_from_env()
          end
        end
    end
  end

  defp guess_port_from_env do
    port = System.get_env("PORT")

    case Integer.parse(port) do
      {value, _} when value > 0 -> value
      _ -> raise "mahou: singyeong: ip loader: couldn't guess port (tried: phx, env)"
    end
  end
end
