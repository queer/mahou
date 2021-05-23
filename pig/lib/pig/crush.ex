defmodule Pig.Crush do
  use Tesla
  alias Pig.Config

  adapter Tesla.Adapter.Finch, name: Pig.Crush.Finch
  plug Tesla.Middleware.BaseUrl, Config.crush_dsn
  plug Tesla.Middleware.JSON

  # TODO: crush should be exposed via sg

  def get(key) do
    case get("/#{key}") do
      {:ok, %Tesla.Env{body: body}} -> {:ok, body}
      {:error, _} = e -> e
    end
  end

  def get_decode(key) do
    case get("/#{key}") do
      {:ok, %Tesla.Env{body: body}} -> {:ok, :erlang.binary_to_term(body)}
      {:error, _} = e -> e
    end
  end

  # crush only understands binaries, so we have to make sure we actually
  # convert values before pushing. This also protects against misuse of the
  # API.
  def set(key, value) when not is_binary(value), do: set key, :erlang.term_to_binary(value)
  def set(key, value) when is_binary(value) do
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
end
