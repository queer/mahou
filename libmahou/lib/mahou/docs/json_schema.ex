defmodule Mahou.Docs.JsonSchema do
  def of(module, type \\ :t) when is_atom(module) do
    json =
      module
      |> GenJsonSchema.gen(type)
      |> Jason.decode!

    # Will raise if invalid schema
    ExJsonSchema.Schema.resolve json
    json
  end
end
