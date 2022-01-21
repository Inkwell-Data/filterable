defmodule Filterable.Utils do
  @moduledoc false

  @spec reduce_with(Enum.t(), any, (Enum.element(), any -> {:cont, {:ok, any}} | {:halt, any})) ::
          any
  def reduce_with(enumerable, acc, fun) do
    Enum.reduce_while(enumerable, {:ok, acc}, fn val, {:ok, acc} ->
      case fun.(val, acc) do
        error = {:error, _} -> {:halt, error}
        value = {:ok, _} -> {:cont, value}
        value -> {:cont, {:ok, value}}
      end
    end)
  end

  @spec to_atoms_map(list | map) :: map
  def to_atoms_map([]), do: []
  def to_atoms_map(%{__struct__: _} = value), do: value

  def to_atoms_map(value) do
    if is_map(value) || Keyword.keyword?(value) do
      Enum.into(value, %{}, fn {k, v} ->
        {ensure_atom(k), to_atoms_map(v)}
      end)
    else
      value
    end
  end

  def presence(value) when value in ["", [], {}, %{}], do: nil
  def presence(value), do: value

  @spec ensure_atom(String.t() | atom) :: atom
  def ensure_atom(value) when is_bitstring(value), do: String.to_atom(value)
  def ensure_atom(value) when is_atom(value), do: value

  @spec ensure_string(String.t() | atom) :: String.t()
  def ensure_string(nil), do: nil
  def ensure_string(value) when is_bitstring(value), do: value
  def ensure_string(value) when is_atom(value), do: Atom.to_string(value)

  def remove_atom(value) when is_atom(value), do: 0
  def remove_atom(value), do: value

  def get_max(defined_filters) do
    {_, v} =
      Enum.max(defined_filters, fn {_, v1}, {_, v2} ->
        remove_atom(Keyword.get(v1, :filter_order, 0)) >=
          remove_atom(Keyword.get(v2, :filter_order, 0))
      end)

    Keyword.get(v, :order, 0)
  end

  def sort_filters_with_order(defined_filters) do
    Enum.sort_by(
      defined_filters,
      fn {_k, v} ->
        case Keyword.get(v, :filter_order, 0) do
          0 -> 0
          :last -> get_max(defined_filters) + 1
          :first -> -1
          val -> val
        end
      end
    )
  end
end
