defmodule Mahou.Message do
  use TypedStruct
  alias Mahou.Message.{ChangeContainerStatus, CreateContainer}

  typedstruct do
    field :ts, non_neg_integer()
    field :payload, ChangeContainerStatus.t()
                    | CreateContainer.t()
  end

  def create(payload) do
    %__MODULE__{
      ts: :os.system_time(:millisecond),
      payload: payload,
    }
  end

  @doc """
  ## Options

  - `json`: Whether or not to b64 to make the payload JSON-safe.
  """
  def encode(payload, opts \\ []) do
    json_safe? = Keyword.get opts, :json, false

    payload
    |> :erlang.term_to_binary
    |> case do
      bin when json_safe? ->
        Base.encode64 bin

      bin ->
        bin
    end
  end

  @doc """
  ## Options

  - `json`: See `encode/2`
  """
  def decode(payload, opts \\ []) do
    json_safe? = Keyword.get opts, :json, false

    payload
    |> case do
      bin when json_safe? ->
        Base.decode64! bin

      bin ->
        bin
    end
    |> :erlang.binary_to_term
  end
end
