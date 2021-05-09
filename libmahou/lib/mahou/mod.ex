defmodule Mahou.Mod do
  def all_mods_where(query) do
    :code.all_available()
    |> Enum.map(fn {mod, _, _} -> mod |> to_string |> String.to_atom end)
    |> Enum.filter(query)
  end

  def peek_json(value) when not is_nil(value) do
    struct_hack = Map.from_struct value.__struct__()
    version = struct_hack[:version] || struct_hack[:v] || 0
    %{
      name: Atom.to_string(value),
      version: version,
      types: Peek.peek(value, json: true),
    }
  end

  def peek_json(value) when is_nil(value) do
    %{
      name: "nil",
      version: 0,
      types: "nil",
    }
  end
end
