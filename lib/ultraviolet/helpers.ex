defmodule Ultraviolet.Helpers do
  @moduledoc false

  # use decimal points because floating point math is weird
  defguard is_byte(b) when is_number(b) and b >= 0 and b <= 255.00001
  defguard is_unit_interval(n) when is_number(n) and n >= 0 and n <= 1.00001
  defguard is_angle(a) when is_number(a) and a >= 0 and a <= 360.00001
  defguard is_under_one(n) when is_number(n) and n >= -1.00001 and n <= 1.00001

  def maybe_round(channel, 0), do: round(channel)

  def maybe_round(channel, digits)
      when is_integer(digits) and is_float(channel) do
    Float.round(channel, digits)
  end

  def maybe_round(channel, _), do: channel

  def clamp_to_byte(n), do: min(max(n, 0), 255)

  def deg_to_rad(n), do: n * :math.pi() / 180.0
  def rad_to_deg(n), do: n * 180.0 / :math.pi()

  @doc """
  validates that every element in a list returns {:ok, result} from
  the given condition function.
  """
  def validate_all(list, condition) do
    list
    |> Enum.map(condition)
    |> Enum.reduce_while([], fn
      {:ok, item}, acc -> {:cont, [item | acc]}
      error, _acc -> {:halt, error}
    end)
    |> case do
      l when is_list(l) -> {:ok, Enum.reverse(l)}
      error -> error
    end
  end

  # coveralls-ignore-start
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

      nil ->
        {:error, :no_match}
    end
  end

  def parse_css_color(_), do: {:error, :no_match}
  # coveralls-ignore-stop
end
