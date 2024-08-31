defmodule Ultraviolet.Color.HSL do
  @moduledoc """
  Functions for working in the HSL color space.
  """
  defstruct h: 0, s: 0.0, l: 0.0, a: 1.0

  @typedoc """
  Defines the channels in an HSL color.
  """
  @type t :: %{h: number(), s: number(), l: number(), a: number()}

  alias Ultraviolet.Color
  alias __MODULE__

  import Ultraviolet.Helpers,
    only: [is_angle: 1, is_unit_interval: 1, maybe_round: 2, clamp_to_byte: 1]

  @me __MODULE__

  @doc """
  Generates a new HSL color object

      iex>Ultraviolet.Color.HSL.new({60, 0.0, 0.5})
      {:ok, %Ultraviolet.Color.HSL{h: 60, s: 0.0, l: 0.5}}

  """
  @spec new(tuple() | [number()] | map() | [...]) :: {:ok, t()}
  def new({h, s, l}), do: new(h, s, l, 1.0)
  def new({h, s, l, a}), do: new(h, s, l, a)
  def new([h, s, l]) when is_number(h), do: new(h, s, l, 1.0)
  def new([h, s, l, a]) when is_number(h), do: new(h, s, l, a)

  # map of channel values
  def new(channels) when is_map(channels) do
    new([
      Map.get(channels, :h),
      Map.get(channels, :s),
      Map.get(channels, :l),
      Map.get(channels, :a, 1.0)
    ])
  end

  # keyword list of channel values
  def new([{k, _} | _rest] = channels) when is_list(channels) and is_atom(k) do
    new(Enum.into(channels, %{}))
  end

  def new(_), do: {:error, :invalid}

  @doc """
  Generates a new HSL color object

      iex>Ultraviolet.Color.HSL.new(60, 0.0, 0.5)
      {:ok, %Ultraviolet.Color.HSL{h: 60, s: 0.0, l: 0.5}}

  """
  @spec new(number(), number(), number()) :: {:ok, t()}
  def new(h, s, l), do: new(h, s, l, 1.0)

  @doc """
  Generates a new HSL color object

      iex>Ultraviolet.Color.HSL.new(60, 0.0, 0.5, 0.5)
      {:ok, %Ultraviolet.Color.HSL{h: 60, s: 0.0, l: 0.5, a: 0.5}}

  """
  @spec new(number(), number(), number(), number()) :: {:ok, t()}
  def new(h, s, l, a)
      when is_angle(h) and is_unit_interval(s) and is_unit_interval(l) and is_unit_interval(a) do
    {:ok, struct(@me, h: h, s: s, l: l, a: a)}
  end

  def new(_, _, _, _), do: {:error, :invalid}

  @doc """
  Converts from HSL to an RGB Color object

  conversion taken from https://wikipedia.org/wiki/HSL_color_space

  ## Options

  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  """
  # achromatic case, e.g. gray
  @spec to_rgb(t()) :: {:ok, Color.t()}
  def to_rgb(%HSL{} = hsl), do: to_rgb(hsl, [])

  @spec to_rgb(t(), [...]) :: {:ok, Color.t()}
  def to_rgb(%HSL{s: s} = hsl, opts) when s == 0 and is_list(opts) do
    round = Keyword.get(opts, :round, 0)

    (hsl.l * 255)
    |> clamp_to_byte()
    |> maybe_round(round)
    |> List.duplicate(3)
    |> then(&Color.new(&1 ++ [hsl.a]))
  end

  def to_rgb(%HSL{l: l, s: s} = hsl, opts) when l < 0.5 and is_list(opts) do
    convert_to_rgb(hsl, l * (1 + s), opts)
  end

  def to_rgb(%HSL{l: l, s: s} = hsl, opts) when is_list(opts) do
    convert_to_rgb(hsl, l + s - l * s, opts)
  end

  defp convert_to_rgb(hsl, q, opts) do
    round = Keyword.get(opts, :round, 0)
    h = hsl.h / 360
    p = 2 * hsl.l - q

    [
      hue_to_rgb(p, q, h + 1 / 3),
      hue_to_rgb(p, q, h),
      hue_to_rgb(p, q, h - 1 / 3)
    ]
    |> Enum.map(&(&1 * 255))
    |> Enum.map(&clamp_to_byte/1)
    |> Enum.map(&maybe_round(&1, round))
    |> then(&Color.new(&1 ++ [hsl.a]))
  end

  defp hue_to_rgb(p, q, t) when t < 0, do: hue_to_rgb(p, q, t + 1)
  defp hue_to_rgb(p, q, t) when t > 1, do: hue_to_rgb(p, q, t - 1)
  defp hue_to_rgb(p, q, t) when t < 1 / 6, do: p + (q - p) * 6 * t
  defp hue_to_rgb(_p, q, t) when t < 0.5, do: q
  defp hue_to_rgb(p, q, t) when t < 2 / 3, do: p + (q - p) * (2 / 3 - t) * 6
  defp hue_to_rgb(p, _, _), do: p

  @doc """
  Converts a Color to HSL

  conversion taken from https://wikipedia.org/wiki/HSL_color_space
  """
  @spec from_rgb(Color.t()) :: {:ok, t()}
  @spec from_rgb(Color.t(), [...]) :: {:ok, t()}
  def from_rgb(%Color{r: r, g: g, b: b, a: a}, options \\ []) when is_list(options) do
    normalized = [r / 255, g / 255, b / 255]
    v = Enum.max(normalized)
    d = v - Enum.min(normalized)
    f = 1 - abs(v + v - d - 1)

    new(
      maybe_round(
        60 * maybe_correct_hue(hue(normalized, v, d)),
        Keyword.get(options, :round, 0)
      ),
      saturation(d, f),
      (v + v - d) / 2,
      a
    )
  end

  defp saturation(_d, f) when f == 0, do: 0.0
  defp saturation(d, f), do: d / f

  defp hue(_, _, d) when d == 0, do: 0
  defp hue([r, g, b], r, d), do: (g - b) / d
  defp hue([r, g, b], g, d), do: 2 + (b - r) / d
  defp hue([r, g, b], b, d), do: 4 + (r - g) / d

  defp maybe_correct_hue(hue) when hue < 0, do: hue + 6
  defp maybe_correct_hue(hue), do: hue
end
