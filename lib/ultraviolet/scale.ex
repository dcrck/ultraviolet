defmodule Ultraviolet.Scale do
  @moduledoc """
  Function related to creating and using color scales.

  Color scales are essentually functions that map numbers to a color palette.
  """

  alias Ultraviolet.Color

  defstruct [
    colors: [%Color{r: 255, g: 255, b: 255}, %Color{}],
    space: :rgb,
    domain: [0, 1],
    padding: [0, 0],
    gamma: 1,
    correct_lightness?: false,
    classes: 0,
    interpolation: :linear,
  ]

  @doc """
  Creates a new color scale. See `Ultraviolet.scale/2` for details about
  creating scales.
  """
  def new(colors, options \\ []) when is_list(options) do
    colors
  end

  @doc """
  Retrieves a single color from the scale at the given value in the domain.
  """
  def fetch(_scale, _x), do: Color.new("black")

  @doc """
  Retrieves a single color from the scale at the given value in the domain.
  If the given value is outside of the domain or otherwise invalid, returns the
  `default` color.
  """
  def get(_scale, _x, default), do: default

  @doc """
  ### If `xs` is a list:

  Returns a map with all the number/color pairs in `scale` where the number is
  in `xs`. If `xs` contains values that are not within the `scale`'s domain,
  they are simply ignored.

  ### If `xs` is a positive integer:

  Returns a list of `xs` equi-distant colors from the scale.
  """
  def take(_scale, xs) when is_list(xs), do: %{}
  def take(_scale, n) when is_integer(n) and n > 0, do: []
end
