defmodule Ultraviolet.Color.HSL do
  defstruct h: 0, s: 0, l: 0, a: 1.0

  alias Ultraviolet.Color
  alias __MODULE__

  @me __MODULE__

  defguardp is_hue(h) when is_integer(h) and h >= 0 and h <= 360
  defguardp is_normalized(n) when (is_float(n) and n >= 0 and n <= 1) or n == 0 or n == 1

  @doc """
  Generates a new HSL color object
  """
  def new(h, s, l), do: new(h, s, l, 1.0)

  def new(h, s, l, a)
  when is_hue(h) and is_normalized(s) and is_normalized(l) and is_normalized(a) do
    {:ok, struct(@me, h: h, s: s, l: l, a: a)}
  end

  def new(_, _, _, _), do: {:error, :invalid}

  @doc """
  Converts from HSL to an RGB Color object

  conversion taken from https://wikipedia.org/wiki/HSL_color_space
  """
  # achromatic case, e.g. gray
  def to_rgb(%HSL{s: s} = hsl) when s == 0 do
    lum = round(hsl.l * 255)
    {:ok, struct(Color, r: lum, g: lum, b: lum, a: hsl.a)}
  end

  def to_rgb(%HSL{l: l, s: s} = hsl) when l < 0.5 do
    convert_to_rgb(hsl, l * (1 + s))
  end

  def to_rgb(%HSL{l: l, s: s} = hsl) do
    convert_to_rgb(hsl, l + s - l * s)
  end

  defp convert_to_rgb(hsl, q) do
    h = hsl.h / 360
    p = 2 * hsl.l - q
    rgb_options = [
      r: round(hue_to_rgb(p, q, h + 1/3) * 255),
      g: round(hue_to_rgb(p, q, h) * 255),
      b: round(hue_to_rgb(p, q, h - 1/3) * 255),
      a: hsl.a,
    ]
    {:ok, struct(Color, rgb_options)}
  end

  defp hue_to_rgb(p, q, t) when t < 0, do: hue_to_rgb(p, q, t + 1)
  defp hue_to_rgb(p, q, t) when t > 1, do: hue_to_rgb(p, q, t - 1)
  defp hue_to_rgb(p, q, t) when t < 1/6, do: p + (q - p) * 6 * t
  defp hue_to_rgb(_p, q, t) when t < 0.5, do: q
  defp hue_to_rgb(p, q, t) when t < 2/3, do: p + (q - p) * (2/3 - t) * 6
  defp hue_to_rgb(p, _, _), do: p

  @doc """
  Converts a Color to HSL

  conversion taken from https://wikipedia.org/wiki/HSL_color_space
  """
  def from_rgb(%Color{r: r, g: g, b: b, a: a}) do
    normalized = [r / 255, g / 255, b / 255]
    v = Enum.max(normalized)
    d = v - Enum.min(normalized)
    f = 1 - abs(v + v - d - 1)
    {
      :ok,
      %HSL{
        h: round(60 * maybe_correct_hue(hue(normalized, v, d))),
        s: saturation(d, f),
        l: (v + v - d) / 2,
        a: a,
      }
    }
  end

  defp saturation(_d, f) when f == 0, do: 0
  defp saturation(d, f), do: d / f

  defp hue(_, _, d) when d == 0, do: 0
  defp hue([r, g, b], r, d), do: (g - b) / d
  defp hue([r, g, b], g, d), do: 2 + (b - r) / d
  defp hue([r, g, b], b, d), do: 4 + (r - g) / d

  defp maybe_correct_hue(hue) when hue < 0, do: hue + 6
  defp maybe_correct_hue(hue), do: hue
end
