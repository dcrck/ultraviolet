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

  pattern = "\\s*(\\d+)\\s*"
  @regex Regex.compile!("^#{pattern},#{pattern},#{pattern}\\)")

  @doc """
  Parses a CSS color in the format `rgb(0,0,0)` into a Color struct.

  Required for `Ultraviolet.ColorBrewer` file.
  """
  def parse_css_color("rgb(" <> rest) do
    case Regex.run(@regex, rest, capture: :all_but_first) do
      [_, _, _] = list ->
        list
        |> Enum.map(&String.to_integer/1)
        |> Ultraviolet.Color.new()
      _ ->
        {:error, :no_match}
    end
  end

  def parse_css_color(_), do: {:error, :no_match}
end
