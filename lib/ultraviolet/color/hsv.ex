defmodule Ultraviolet.Color.HSV do
  @moduledoc """
  Functions for working in the HSV color space
  """
  defstruct h: 0, s: 0, v: 0, a: 1.0
  @type t :: %{h: number(), s: number(), v: number(), a: number()}

  alias Ultraviolet.Color
  alias Ultraviolet.Color.HSL
  alias __MODULE__

  import Ultraviolet.Helpers,
    only: [is_angle: 1, is_unit_interval: 1]

  @me __MODULE__

  @doc """
  Generates a new HSV color object

      iex>Ultraviolet.Color.HSV.new({60, 0.0, 0.5})
      {:ok, %Ultraviolet.Color.HSV{h: 60, s: 0.0, v: 0.5}}

  """
  @spec new(tuple() | [number()] | map() | [...]) :: {:ok, t()}
  def new({h, s, v}), do: new(h, s, v, 1.0)
  def new({h, s, v, a}), do: new(h, s, v, a)
  def new([h, s, v]) when is_number(h), do: new(h, s, v, 1.0)
  def new([h, s, v, a]) when is_number(h), do: new(h, s, v, a)

  # map of channel values
  def new(channels) when is_map(channels) do
    new([
      Map.get(channels, :h),
      Map.get(channels, :s),
      Map.get(channels, :v),
      Map.get(channels, :a, 1.0)
    ])
  end

  # keyword list of channel values
  def new([{k, _} | _rest] = channels) when is_list(channels) and is_atom(k) do
    new(Enum.into(channels, %{}))
  end

  @doc """
  Generates a new HSV color object

      iex>Ultraviolet.Color.HSV.new(60, 0.0, 0.5)
      {:ok, %Ultraviolet.Color.HSV{h: 60, s: 0.0, v: 0.5}}
  """
  @spec new(number(), number(), number()) :: {:ok, t()}
  def new(h, s, v), do: new(h, s, v, 1.0)

  @doc """
  Generates a new HSV color object

      iex>Ultraviolet.Color.HSV.new(60, 0.0, 0.5, 0.5)
      {:ok, %Ultraviolet.Color.HSV{h: 60, s: 0.0, v: 0.5, a: 0.5}}
  """
  @spec new(number(), number(), number(), number()) :: {:ok, t()}
  def new(h, s, v, a)
      when is_angle(h) and is_unit_interval(s) and is_unit_interval(v) and is_unit_interval(a) do
    {:ok, struct(@me, h: h, s: s, v: v, a: a)}
  end

  def new(_, _, _, _), do: {:error, :invalid}

  @doc """
  Converts from HSV to an RGB Color object

  ## Options

  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  """
  @spec to_rgb(t()) :: {:ok, Color.t()}
  def to_rgb(%HSV{} = hsv), do: to_rgb(hsv, [])

  @spec to_rgb(t(), [...]) :: {:ok, Color.t()}
  def to_rgb(%HSV{s: s, v: v, h: h, a: a} = hsv, options)
      when is_list(options) and ((s == 0 and v == 1) or v == 0) do
    l = lightness_from_hsv(hsv)
    {:ok, hsl} = HSL.new(h, 0, l, a)
    HSL.to_rgb(hsl, options)
  end

  def to_rgb(%HSV{h: h, v: v, a: a} = hsv, options)
      when is_list(options) do
    l = lightness_from_hsv(hsv)
    {:ok, hsl} = HSL.new(h, (v - l) / min(l, 1 - l), l, a)
    HSL.to_rgb(hsl, options)
  end

  defp lightness_from_hsv(%{v: v, s: s}), do: v * (1 - s / 2)

  @doc """
  Converts a Color to HSV

  ## Options

  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  """
  @spec from_rgb(Color.t()) :: {:ok, t()}
  @spec from_rgb(Color.t(), [...]) :: {:ok, t()}
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    {:ok, hsl} = HSL.from_rgb(color, options)
    hsl_to_hsv(hsl, hsl.l + hsl.s * min(hsl.l, 1 - hsl.l))
  end

  defp hsl_to_hsv(%HSL{h: h, a: a}, v) when v == 0 do
    new(h, 0, 0, a)
  end

  defp hsl_to_hsv(%{h: h, a: a, l: l}, v) do
    new(h, 2 * (1 - l / v), v, a)
  end
end
