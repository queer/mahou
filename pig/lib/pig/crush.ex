defmodule Pig.Crush do
  use Tesla
  alias Mahou.Format.App
  alias Pig.Config

  adapter Tesla.Adapter.Finch, name: Pig.Crush.Finch
  plug Tesla.Middleware.BaseUrl, Config.crush_dsn()
  plug Tesla.Middleware.JSON

  # TODO: crush should probably be exposed via sg?

  def get_key(key) do
    case get("/#{key}") do
      {:ok, %Tesla.Env{body: body}} -> {:ok, body}
      {:error, _} = e -> e
    end
  end

  def get_decode(key) do
    case get("/#{key}?patch=true") do
      {:ok, %Tesla.Env{body: []}} -> {:ok, []}
      {:ok, %Tesla.Env{body: [elem, patches]}} ->

        elem =
          elem
          |> Base.decode64!
          |> :erlang.binary_to_term

        patches =
          Enum.map patches, fn patch ->
            patch
            |> Base.decode64!
            |> :erlang.binary_to_term
          end

        {:ok, {elem, patches}}

      {:error, _} = e -> e
    end
  end

  # crush only understands binaries, so we have to make sure we actually
  # convert values before pushing. This also protects against misuse of the
  # API.
  def set(key, value) when not is_binary(value) do
    enc = :erlang.term_to_binary(value)
    set key, enc
  end

  def set(key, value) when is_binary(value) do
    IO.puts "sending body: #{byte_size(value)}"
    case put("/#{key}", value) do
      {:ok, %Tesla.Env{body: body}} -> {:ok, body}
      {:error, _} = e -> e
    end
  end

  def del(key) do
    case delete("/#{key}") do
      {:ok, %Tesla.Env{body: %{"status" => "ok"}}} -> :ok
      {:error, _} = e -> e
    end
  end

  def keys(prefix) do
    case get("/keys?prefix=#{prefix}") do
      {:ok, %Tesla.Env{body: keys}} -> {:ok, keys}
      {:error, _} = e -> e
    end
  end

  def deployments do
    case keys("mahou:deployment:") do
      {:ok, keys} ->
        keys
        |> Enum.map(&Enum.at(String.split(&1, ":", parts: 2), 1))
        |> Enum.map(&get_decode(&1))
        |> Enum.reject(fn x -> elem(x, 0) != :ok end)
        |> Enum.map(&elem(&1, 1))
        |> Enum.map(fn {deploy, _patches} ->
          deploy
        end)
        |> Enum.reject(&is_integer/1)

      {:error, _} -> []
    end
  end

  def format_deploy(%App{name: name, namespace: ns}) do
    "mahou:deployment:#{ns || "default"}:#{name}"
  end
end
