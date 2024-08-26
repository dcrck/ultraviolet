defmodule Ultraviolet.Color.HSV do
  @moduledoc """
  Functions for working in the HSV color space
  """
  defstruct h: 0, s: 0, v: 0, a: 1.0

  alias Ultraviolet.Color
  alias Ultraviolet.Color.HSL
  alias __MODULE__

  @me __MODULE__
  
  defguardp is_hue(h) when is_number(h) and h >= 0 and h <= 360
  defguardp is_normalized(n) when is_number(n) and n >= 0 and n <= 1

  def new(h, s, v), do: new(h, s, v, 1.0)

  def new(h, s, v, a)
  when is_hue(h) and is_normalized(s) and is_normalized(v) and is_normalized(a) do
    {:ok, struct(@me, h: h, s: s, v: v, a: a)}
  end
  
  def new(_, _, _, _), do: {:error, :invalid}

  @doc """
  Converts from HSV to an RGB Color object
  """
  def to_rgb(%HSV{s: s, v: v, h: h, a: a}) when (s == 0 and v == 1) or v == 0 do
    l = v * (1 - s / 2)
    {:ok, hsl} = HSL.new(h, 0, l, a)
    HSL.to_rgb(hsl)
  end

  def to_rgb(%HSV{h: h, s: s, v: v, a: a}) do
    l = v * (1 - s / 2)
    {:ok, hsl} = HSL.new(h, (v - l) / min(l, 1 - l), l, a)
    HSL.to_rgb(hsl)
  end

  @doc """
  Converts a Color to HSV
  """
  def from_rgb(%Color{} = color) do
    {:ok, hsl} = HSL.from_rgb(color)
    hsl_to_hsv(hsl, hsl.l + hsl.s * min(hsl.l, 1 - hsl.l))
  end

  defp hsl_to_hsv(%HSL{h: h, a: a}, v) when v == 0 do
    new(h, 0, 0, a)
  end

  defp hsl_to_hsv(%{h: h, a: a, l: l}, v) do
    new(h, 2 * (1 - l / v), v, a)
  end
end
