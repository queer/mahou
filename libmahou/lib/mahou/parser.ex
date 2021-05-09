defmodule Mahou.Parser do
  @spec parse(String.t()) :: term()
  def parse(config) do
    {res, _} = Code.eval_file config
    res
  end
end
