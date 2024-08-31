defmodule Ultraviolet.Color.OKLCH do
  @moduledoc """
  Functions for wokring with the OKLCH color space.

  OKLCH is to LCH as OKLab is to Lab.

  Uses the `:d65` reference illuminant.
  """
  defstruct l: 0, c: 0, h: 0, a: 1.0
  @type t :: %{l: number(), c: number(), h: number(), a: number()}

  alias Ultraviolet.Color
  alias Ultraviolet.Color.OKLab
  alias __MODULE__

  import Ultraviolet.Helpers,
    only: [
      maybe_round: 2,
      is_angle: 1,
      is_unit_interval: 1,
      deg_to_rad: 1,
      rad_to_deg: 1
    ]

  @doc """
  Generates a new LCH color

      iex>Ultraviolet.Color.LCH.new({0.5, 0.0, 60})
      {:ok, %Ultraviolet.Color.LCH{h: 60, c: 0.0, l: 0.5}}

  """
  @spec new(tuple() | [number()] | map() | [...]) :: {:ok, t()}
  def new({l, c, h}), do: new(l, c, h, 1.0)
  def new({l, c, h, a}), do: new(l, c, h, a)
  def new([l, c, h]) when is_number(l), do: new(l, c, h, 1.0)
  def new([l, c, h, a]) when is_number(l), do: new(l, c, h, a)

  # map of channel values
  def new(channels) when is_map(channels) do
    new([
      Map.get(channels, :l),
      Map.get(channels, :c),
      Map.get(channels, :h),
      Map.get(channels, :a, 1.0)
    ])
  end

  # keyword list of channel values
  def new([{k, _} | _rest] = channels) when is_list(channels) and is_atom(k) do
    new(Enum.into(channels, %{}))
  end

  @doc """
  Generates a new OKLCH color object

      iex>Ultraviolet.Color.OKLCH.new(0.5, 0.0, 60)
      {:ok, %Ultraviolet.Color.OKLCH{h: 60, c: 0.0, l: 0.5}}

  """
  @spec new(number(), number(), number()) :: {:ok, t()}
  def new(l, c, h), do: new(l, c, h, 1.0)

  @doc """
  Generates a new OKLCH color object

      iex>Ultraviolet.Color.OKLCH.new(0.5, 0.0, 60, 0.5)
      {:ok, %Ultraviolet.Color.OKLCH{h: 60, c: 0.0, l: 0.5, a: 0.5}}

  """
  @spec new(number(), number(), number(), number()) :: {:ok, t()}
  def new(l, c, h, a)
      when is_angle(h) and is_unit_interval(l) and is_unit_interval(c) and is_unit_interval(a) do
    {:ok, struct(OKLCH, h: h, c: c, l: l, a: a)}
  end

  @doc """
  Converts from OKLCH to sRGB

  ## Options

    - `:round`: an integer if rounding r, g, and b channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `0`

  """
  def to_rgb(%OKLCH{} = lch, options \\ []) when is_list(options) do
    case oklch_to_oklab(lch) do
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
  @spec from_rgb(Color.t()) :: {:ok, t()}
  @spec from_rgb(Color.t(), [...]) :: {:ok, t()}
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    case OKLab.from_rgb(color, Keyword.merge(options, round: false)) do
      {:ok, oklab} -> oklab_to_oklch(oklab, options)
      error -> error
    end
  end

  defp oklch_to_oklab(%OKLCH{l: l, c: c, h: h, a: a}) do
    h
    |> deg_to_rad()
    |> then(&OKLab.new(l, :math.cos(&1) * c, :math.sin(&1) * c, a))
  end

  defp oklab_to_oklch(%OKLab{a_: a, b_: b} = oklab, options) do
    round = Keyword.get(options, :round, 2)
    c = :math.sqrt(a * a + b * b)

    h =
      cond do
        round(c * 10000) == 0 -> 0
        true -> mod(rad_to_deg(:math.atan2(b, a)) + 360, 360)
      end

    [oklab.l_, c, h]
    |> Enum.map(&maybe_round(&1, round))
    |> then(&new(&1 ++ [oklab.a]))
  end

  # simple floating-point modulus
  defp mod(n, x) when n >= 0 and n < x, do: n
  defp mod(n, x) when n >= 0, do: mod(n - x, n)
end
