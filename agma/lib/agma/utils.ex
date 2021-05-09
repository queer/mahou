defmodule Agma.Utils do
  def snake(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      k =
        k
        |> snake
        |> String.replace("i_pv", "ipv")
      cond do
        is_struct(v) ->
          {k, snake(Map.from_struct(v))}

        is_map(v) ->
          {k, snake(v)}

        is_list(v) ->
          {k, Enum.map(v, &snake/1)}

        true ->
          {k, v}
      end
    end)
    |> Enum.into(%{})
  end

  def snake(list) when is_list(list), do: Enum.map list, &snake/1
  def snake(str) when is_binary(str), do: Macro.underscore str
  def snake(not_map), do: not_map

  def atomify(term, ignore_inside \\ [], prev \\ nil)
  def atomify(map, ignore_inside, prev) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      k =
        if prev in ignore_inside do
          k
        else
          String.to_atom k
        end

      cond do
        is_struct(v) ->
          {k, atomify(Map.from_struct(v), ignore_inside, k)}

        is_map(v) ->
          {k, atomify(v, ignore_inside, k)}

        is_list(v) ->
          {k, Enum.map(v, &atomify(&1, ignore_inside, k))}

        true ->
          {k, v}
      end
    end)
    |> Enum.into(%{})
  end

  def atomify(list, ignore_inside, prev) when is_list(list), do: Enum.map list, &atomify(&1, ignore_inside, prev)
  def atomify(not_map, _, _), do: not_map

  def structify!(fields, struct) when is_list(fields) and is_atom(struct), do: Enum.map fields, &structify!(struct, &1)
  def structify!(fields, struct) when is_map(fields) and is_atom(struct), do: struct!(struct, fields)
  def structify!(term, _), do: term
end
