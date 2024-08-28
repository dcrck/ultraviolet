defmodule Ultraviolet.Helpers do
  @moduledoc false

  @doc """
  validates that every element in a list returns {:ok, result} from
  the given condition function.
  """
  def validate_all(list, condition) do
    list
    |> Enum.map(condition)
    |> Enum.reduce_while([], fn
      {:ok, item}, acc -> {:cont, [item | acc]}
      error, _ -> {:halt, error}
    end)
    |> case do
      l when is_list(l) -> {:ok, Enum.reverse(l)}
      error -> error
    end
  end
end
