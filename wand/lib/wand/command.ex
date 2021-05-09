defmodule Wand.Command do
  @callback run(Keyword.t(), [String.t()]) :: :ok | {:error, term()}
end
