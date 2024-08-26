defmodule Ultraviolet.Color.OKLCH do
  @moduledoc """
  Functions for wokring with the OKLCH color space.

  OKLCH is to LCH as OKLab is to Lab.

  Uses the `:d65` reference illuminant.
  """
  defstruct l: 0, c: 0, h: 0, a: 1.0

  alias Ultraviolet.Color
  alias Ultraviolet.Color.OKLab
  alias __MODULE__

  defguardp is_hue(h) when is_integer(h) and h >= 0 and h <= 360
  defguardp is_normalized(n) when is_number(n) and n >= 0 and n <= 1.00001

  def new(l, c, h), do: new(l, c, h, 1.0)

  def new(l, c, h, a)
  when is_hue(h) and is_normalized(l) and is_normalized(c) and is_normalized(a) do
    {:ok, struct(OKLCH, h: h, c: c, l: l, a: a)}
  end

  @doc """
  Converts from OKLCH to sRGB

  ## Options

    - `:round`: an integer if rounding r, g, and b channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `0`
  """
  def to_rgb(%OKLCH{} = lch, options \\ []) when is_list(options) do
    case lch_to_oklab(lch) do
      {:ok, oklab} -> OKLab.to_rgb(oklab, options)
      error -> error
    end
  end

  @doc """
  Converts from an RGB Color struct to a LCH struct.
  
  ## Options

    - `:round`: an integer if rounding L, a*, and b* channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `2`
  """
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    case OKLab.from_rgb(color, Keyword.merge(options, round: false)) do
      {:ok, oklab} -> oklab_to_lch(oklab, options)
      error -> error
    end
  end

  # degrees to radians
  defp deg_to_rad(n), do: n * :math.pi() / 180.0
  # radians to degrees
  defp rad_to_deg(n), do: n * 180.0 / :math.pi()

  defp lch_to_oklab(%OKLCH{l: l, c: c, h: h, a: a}) do
    h
    |> deg_to_rad()
    |> then(&OKLab.new(l, :math.cos(&1) * c, :math.sin(&1) * c, a))
  end

  defp oklab_to_lch(%OKLab{a_star: a, b_star: b} = oklab, options) do
    round = Keyword.get(options, :round, 2)
    c = :math.sqrt(a * a + b * b)
    h = cond do
      round(c * 10000) == 0 -> 0
      true -> mod(rad_to_deg(:math.atan2(b, a)) + 360, 360)
    end

    [oklab.l, c, h]
    |> Enum.map(&maybe_round(&1, round))
    |> then(fn [l, c, h] -> {:ok, %OKLCH{l: l, c: c, h: h, a: oklab.a}} end)
  end

  # simple floating-point modulus
  defp mod(n, x) when n >= 0 and n < x, do: n
  defp mod(n, x) when n >= 0, do: mod(n - x, n)

  defp maybe_round(channel, 0), do: round(channel)
  defp maybe_round(channel, digits) when is_integer(digits) and is_float(channel) do
    Float.round(channel, digits)
  end

  defp maybe_round(channel, _), do: channel
end
